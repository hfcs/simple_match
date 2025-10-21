import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  const channelName = 'plugins.flutter.io/path_provider';

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  testWidgets(
    'Import Backup UI flow (select file, dry-run, restore) updates repository',
    (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');

    // Create a minimal valid backup file
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final file = File('${tmpDir.path}/sm_ui_backup.json');
    await file.writeAsString(jsonEncode(backup));

    // We'll inject deterministic overrides so we don't rely on platform path_provider
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();


    // Provide pickBackupOverride so tests can simulate user picking a file.
    final bytes = await File(file.path).readAsBytes();
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': file.path.split('/').last, 'autoConfirm': true},
          ),
        ),
      ),
    );

  await tester.pump();

    // Drive the UI interactions inside runAsync to allow long-running async work
    await tester.runAsync(() async {
      // Tap Import Backup
      final importFinder = find.text('Import Backup');
      expect(importFinder, findsOneWidget);
      
      await tester.tap(importFinder);
  await tester.pumpAndSettle();

      // Wait until the filename option appears (SimpleDialog may take a frame)
      var tries = 0;
      while (find.text('sm_ui_backup.json').evaluate().isEmpty && tries < 40) {
        await tester.pump(const Duration(milliseconds: 50));
        tries++;
      }


      // The SimpleDialog should show an option with the filename; tap it
      final filenameFinder = find.text('sm_ui_backup.json');
      
      expect(filenameFinder, findsOneWidget);
      
      await tester.tap(filenameFinder);
  await tester.pumpAndSettle();

      // Confirmation AlertDialog should appear; tap 'Restore'
      final restoreFinder = find.text('Restore');
      
      expect(restoreFinder, findsOneWidget);
      
      await tester.tap(restoreFinder);

      // Allow async operations to complete (import, repo.loadAll())
  // Give some time for import and repo.loadAll() to complete
  await Future.delayed(const Duration(seconds: 1));
    });

    // Let the framework finish any remaining scheduled frames
    await tester.pumpAndSettle();

    // Verify import result: repo now contains shooter 'Eve'
    expect(repo.getShooter('Eve')?.name, equals('Eve'));

    // Cleanup
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
    },
  // This UI-driven test is flaky in CI (dialog/async timing). Keep it in
  // the tree for local debugging but skip it in automated runs. Use the
  // deterministic `settings_view_import_direct_test.dart` in CI instead.
  skip: true,
    timeout: Timeout(Duration(seconds: 60)),
  );
}
