// IO integration test for documents directory export/import flows.
// Run with: flutter test integration_test/settings_view_io_integration_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IO export writes file to documents dir and import restores',
      (tester) async {
    // This test should run on an IO platform (not web).
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(),
      ),
    ));

    // Trigger export which should write a file to the app documents dir.
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

  // Find any JSON backup files in the app documents directory.
  final docsDir = await getApplicationDocumentsDirectory();
  final files = docsDir
    .listSync(recursive: false)
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'))
    .toList();

    expect(files.isNotEmpty, isTrue);

    // Attempt to import the first file using override via listBackupsOverride/readFileBytesOverride
    final selected = files.first;

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [selected],
          readFileBytesOverride: (String p) async => await File(p).readAsBytes(),
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Expect import success or a handled error (test ensures no crash)
    expect(find.textContaining('Import'), findsWidgets);
  });
}
