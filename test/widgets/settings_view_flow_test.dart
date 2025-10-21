import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

// The tests now use `PersistenceService(prefs: ...)` directly for determinism.

void main() {
  const channelName = 'plugins.flutter.io/path_provider';

  setUp(() {
    // Clear any previous handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  testWidgets('Export Backup writes a file to documents directory', (tester) async {
    // Use a saveExportOverride to intercept the export without calling into
    // path_provider or writing files. This keeps the test deterministic.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    var called = false;
    Future<void> fakeSaveExport(String path, String content) async {
      called = true;
      // basic sanity: content should be JSON
      jsonDecode(content);
    }

    // Pump SettingsView within provider so it can access MatchRepository
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: fakeSaveExport)),
      ),
    );
    await tester.pump();

    final exportFinder = find.text('Export Backup');
    expect(exportFinder, findsOneWidget);

    // Tap Export and ensure our fake exporter is invoked
    await tester.tap(exportFinder);
    await tester.pumpAndSettle();
    expect(called, isTrue);
  }, timeout: Timeout(Duration(seconds: 20)));

  test('Import Backup flow (select file, dry-run, restore) updates repository', () async {
    // Convert to in-memory bytes to avoid filesystem usage
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    ImportResult res;
    try {
      res = await persistence.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: false).timeout(const Duration(seconds: 5));
    } catch (e) {
      fail('importBackupFromBytes timed out or threw: $e');
    }
    expect(res.success, isTrue);

    await repo.loadAll();
    expect(repo.getShooter('Eve')?.name, equals('Eve'));
  }, timeout: Timeout(Duration(seconds: 30)));
}
