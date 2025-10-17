import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Export -> Import end-to-end', (tester) async {
    // For integration-style UI test we will pump a SettingsView and exercise the
    // Import dialog flow. Use a clean SharedPreferences instance for isolation.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Use the app documents directory for backup files
    final docs = await getApplicationDocumentsDirectory();

    // Create a backup file in the app documents directory with one shooter
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'IntegrationEve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final file = File('${docs.path}/sm_integ_backup.json');
    await file.writeAsString(jsonEncode(backup));

    // Pump a SettingsView and provide a MatchRepository wired to the test prefs
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

    // Tap Import Backup; this will show a dialog listing files in documents dir
    final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    await tester.pumpAndSettle();

    // The dialog should list our file by name
    final name = file.path.split('/').last;
    final optionFinder = find.widgetWithText(SimpleDialogOption, name);
    expect(optionFinder, findsOneWidget);
    await tester.tap(optionFinder);
    await tester.pumpAndSettle();

    // Confirm Restore in the confirmation dialog
    final restoreFinder = find.widgetWithText(TextButton, 'Restore');
    expect(restoreFinder, findsOneWidget);
    await tester.tap(restoreFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify persistence contains the imported shooter
    final shootersJson = prefs.getString('shooters');
    expect(shootersJson, isNotNull);
    final shooters = jsonDecode(shootersJson!) as List;
    final found = shooters.any((s) => (s as Map)['name'] == 'IntegrationEve');
    expect(found, isTrue);

    // cleanup
    try {
      await file.delete();
    } catch (_) {}
  });
}
