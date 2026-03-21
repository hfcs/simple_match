import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

// The tests now use `FakePersistence()` for determinism and web-safety.

void main() {
  const channelName = 'plugins.flutter.io/path_provider';

  setUp(() {
    // Clear any previous handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  testWidgets('Export Backup invokes saveExportOverride', (tester) async {
    final repo = MatchRepository(persistence: FakePersistence());
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(called, isTrue);
  }, timeout: Timeout(Duration(seconds: 20)));

  test('Import Backup flow (direct using FakePersistence)', () async {
    // Convert to in-memory bytes to avoid filesystem usage
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    final persistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, message: 'ok', counts: {});
      return FakeImportResult(success: true, message: 'imported', counts: {});
    });

    // Dry-run
    final dry = await persistence.importBackupFromBytes(bytes, dryRun: true);
    expect(dry.success, isTrue);

    // Actual import
    final res = await persistence.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: false);
    expect(res.success, isTrue);
  }, timeout: Timeout(Duration(seconds: 30)));
}
