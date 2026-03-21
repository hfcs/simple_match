import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration: SettingsView IO import dialog flow', (tester) async {
    // Prepare a temp dir and backup file
    final tmpDir = Directory.systemTemp.createTempSync('sm_integ_docs_');
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final file = File('${tmpDir.path}/sm_integ_backup.json');
    await file.writeAsString(jsonEncode(backup));

    // Mock path_provider to return our temp dir
    const channelName = 'plugins.flutter.io/path_provider';
    final mc = MethodChannel(channelName);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(mc, (call) async {
      return tmpDir.path;
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Pump the SettingsView
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: SettingsView()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Import Backup
    final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    await tester.pumpAndSettle();

    // Wait for the SimpleDialog option and tap the filename
    final filenameFinder = find.text(file.path.split('/').last);
    var tries = 0;
    while (filenameFinder.evaluate().isEmpty && tries < 40) {
      await tester.pump(const Duration(milliseconds: 50));
      tries++;
    }
    expect(filenameFinder, findsOneWidget);
    await tester.tap(filenameFinder);
    await tester.pumpAndSettle();

    // Wait for confirmation dialog and tap 'Restore'
    final restoreFinder = find.text('Restore');
    tries = 0;
    while (restoreFinder.evaluate().isEmpty && tries < 40) {
      await tester.pump(const Duration(milliseconds: 50));
      tries++;
    }
    expect(restoreFinder, findsOneWidget);
    await tester.tap(restoreFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Reload repo and assert imported shooter exists
    await repo.loadAll();
    expect(repo.getShooter('Eve')?.name, equals('Eve'));

    // Cleanup
    try { tmpDir.deleteSync(recursive: true); } catch (_) {}
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(mc, null);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
