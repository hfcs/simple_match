// Web-targeted SettingsView test using SharedPreferences-backed persistence
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('SettingsView web import/export override flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Provide a saveExportOverride that captures content written by the UI
    String? savedContent;
    Future<void> saveExportOverride(String path, String content) async {
      savedContent = content;
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: saveExportOverride)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Export Backup and ensure our override received JSON
    expect(find.text('Export Backup'), findsOneWidget);
    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(savedContent, isNotNull);
    expect(savedContent!.contains('metadata'), isTrue);

    // Prepare an import payload (backup JSON) and use pickBackupOverride to simulate user choosing it
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'WebTest', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'webtest.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Import Backup and confirm the repo contains the imported shooter afterwards
    expect(find.text('Import Backup'), findsOneWidget);
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    await repo.loadAll();
    expect(repo.getShooter('WebTest')?.name, equals('WebTest'));
  });
}
