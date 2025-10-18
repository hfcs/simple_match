import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('SettingsView IO export -> import flow (documents dir) [integration]', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Prepare a temporary directory to act as application documents directory
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');

    // Mock path_provider method channel to return our temp dir path
    const channelName = 'plugins.flutter.io/path_provider';
    final channel = const MethodChannel(channelName);
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall method) async {
      // For any getApplicationDocumentsDirectory call return temp dir path
      return tmpDir.path;
    });

    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView()),
      ),
    );
    await tester.pumpAndSettle();

    // Create an export file directly (avoid flaky Export UI in test env)
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportPath = '${tmpDir.path}${Platform.pathSeparator}simple_match_backup_$ts.json';
    await persistence.exportBackupToFile(exportPath);

    // Verify that a JSON file exists in tmpDir
    final files = tmpDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
    expect(files.isNotEmpty, isTrue, reason: 'Expected exported JSON in tmp dir');

    // Now tap Import Backup and choose the created file
    final importBtn = find.text('Import Backup');
    expect(importBtn, findsOneWidget);
    await tester.tap(importBtn);
    await tester.pumpAndSettle();

    final name = files.first.path.split(Platform.pathSeparator).last;
    final optionFinder = find.widgetWithText(SimpleDialogOption, name);
    expect(optionFinder, findsOneWidget);
    await tester.tap(optionFinder);
    await tester.pumpAndSettle();

    // Confirm restore
    final restoreFinder = find.widgetWithText(TextButton, 'Restore');
    expect(restoreFinder, findsOneWidget);
    await tester.tap(restoreFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // After import we expect a success message in Scaffold or status text
    expect(find.textContaining('Import successful'), findsWidgets);

    // cleanup
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}

    // Clear the mock
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
}
