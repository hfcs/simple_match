import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exporter exception sets Export failed and shows SnackBar', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');

    Future<Never> exporter(String path, String content) async {
      throw Exception('export boom');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: MatchRepository(persistence: fake),
        child: SettingsView(saveExportOverride: exporter),
      ),
    ));

    // Trigger export via tapping the button
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('force web export path via forceKIsWeb executes exportViaWebForTest', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');

    var called = false;
    Future<void> exporter(String name, String content) async {
      called = true;
    }

    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: MatchRepository(persistence: fake),
        child: SettingsView(saveExportOverride: exporter),
      ),
    ));

    // Call the web wrapper directly from state to avoid platform kIsWeb checks
    final state = tester.state(find.byType(SettingsView));
    await (state as dynamic).exportViaWebForTest(tester.element(find.byType(SettingsView)), fake, exporter, 'ts');
    await tester.pumpAndSettle();

    expect(called, isTrue);

    SettingsView.forceKIsWeb = false;
  });

  testWidgets('import via web returns no file selected shows SnackBar', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{}');

    // pickBackupOverride returns null to simulate cancel/no file
    Future<Null> pickNull() async => null;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: MatchRepository(persistence: fake),
        child: SettingsView(pickBackupOverride: pickNull),
      ),
    ));

    // Invoke import which will call the pick override
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No file selected'), findsWidgets);
  });

  testWidgets('import dry-run failure shows validation failed message', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{}', importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad');
      return FakeImportResult(success: true);
    });

    Future<Map<String, Object>> pick() async => {'bytes': Uint8List.fromList([9, 9]), 'name': 'bad.json', 'autoConfirm': true};

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: MatchRepository(persistence: fake),
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });
}
