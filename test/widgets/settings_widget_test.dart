import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/main.dart' as app;
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  testWidgets('Tapping Settings opens SettingsView', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(app.MiniIPSCMatchApp(repository: repo));
    await tester.pumpAndSettle();

    // The main menu contains a 'Settings' entry
    final settingsFinder = find.text('Settings');
    expect(settingsFinder, findsOneWidget);

    await tester.tap(settingsFinder);
    await tester.pumpAndSettle();

    // SettingsView should be displayed with Export Backup button
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Import Backup'), findsOneWidget);
  });

  testWidgets('Importing backup updates UI via repository reload', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Simple test app that shows first shooter name or placeholder
    final testApp = MultiProvider(
      providers: [
        ChangeNotifierProvider<MatchRepository>.value(value: repo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer<MatchRepository>(builder: (context, r, _) {
            final shooters = r.shooters;
            return Text(shooters.isEmpty ? 'No shooters' : shooters.first.name);
          }),
        ),
      ),
    );

    await tester.pumpWidget(testApp);
    await tester.pumpAndSettle();

    expect(find.text('No shooters'), findsOneWidget);

    // Build backup JSON with one shooter
    final map = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Dana', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));

    final res = await persistence.importBackupFromBytes(bytes, dryRun: false);
    expect(res.success, isTrue);

    // Reload repository which now notifies listeners
    await repo.loadAll();
    await tester.pumpAndSettle();

    // UI should now show the restored shooter
    expect(find.text('Dana'), findsOneWidget);
  });
}
