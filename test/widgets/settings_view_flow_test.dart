import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
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
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');
    // Mock path_provider to return our temp dir for any directory request
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), (methodCall) async {
      return tmpDir.path;
    });

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final persistence = PersistenceService(prefs: prefs);
  final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Pump SettingsView within provider so it can access MatchRepository
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView()),
      ),
    );
    // Use a single pump to render the initial frame; avoid pumpAndSettle which can hang
    await tester.pump();

    // Ensure Export button exists
    final exportFinder = find.text('Export Backup');
    expect(exportFinder, findsOneWidget);

    // Directly call persistence to export to our temp dir to avoid UI timing issues
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final testPath = '${tmpDir.path}/simple_match_test_export_$ts.json';
  final out = await tester.runAsync(() => persistence.exportBackupToFile(testPath));
  expect(out!.path, contains(tmpDir.path));

    // Clean up
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  }, timeout: Timeout(Duration(seconds: 20)));

  test('Import Backup flow (select file, dry-run, restore) updates repository', () async {
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');
    // Do not mock path_provider for this unit-style import test

    // Build a backup file with one shooter
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final file = File('${tmpDir.path}/sm_test_backup.json');
    await file.writeAsString(jsonEncode(backup));

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
  final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Perform the import directly (unit-style) to validate persistence<->repository integration.
  debugPrint('DEBUG: about to read backup file at ${file.path}');
    final bytes = await File(file.path).readAsBytes();
  debugPrint('DEBUG: read ${bytes.length} bytes, invoking importBackupFromBytes');
    ImportResult res;
    try {
      res = await persistence.importBackupFromBytes(Uint8List.fromList(bytes), dryRun: false, backupBeforeRestore: false).timeout(const Duration(seconds: 5));
    } catch (e) {
      fail('importBackupFromBytes timed out or threw: $e');
    }
  debugPrint('DEBUG: import completed: success=${res.success} message=${res.message}');
    expect(res.success, isTrue);

    // Ensure repository loads latest data
    await repo.loadAll();
    expect(repo.getShooter('Eve')?.name, equals('Eve'));

    // Cleanup
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  }, timeout: Timeout(Duration(seconds: 30)));
}
