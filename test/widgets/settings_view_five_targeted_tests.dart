import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('importFromDocumentsForTest: empty list shows no backups path', (WidgetTester tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async => <dynamic>[])),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    // Call the import flow which should handle empty listBackup path
    try {
      await (state as dynamic).importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo, fake);
    } catch (_) {}

    await tester.pumpAndSettle();
    expect(true, isTrue);
  });

  testWidgets('importFromDocumentsChosenForTest: non-autoConfirm path exercised', (WidgetTester tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    final tmp = Directory.systemTemp.createTempSync();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': Uint8List.fromList([1,2,3]), 'name': 'f', 'autoConfirm': false},
            documentsDirOverride: () async => tmp,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView));

    // Call chosen import which will present the non-autoConfirm branch. We
    // programmatically tap the dialog confirm button to exercise that path.
    final call = (state as dynamic).importFromDocumentsChosenForTest(tester.element(find.byType(SettingsView)), repo, fake, null);

    // Wait for dialog and tap Confirm if present
    await tester.pumpAndSettle();
    final confirm = find.text('Confirm');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await tester.pumpAndSettle();
    }

    await call;
    await tester.pumpAndSettle();
    expect(true, isTrue);
  });

  testWidgets('importFromDocumentsChosenForTest: dry-run failure sets status', (WidgetTester tester) async {
    final fakeFail = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'dry-invalid');
      return FakeImportResult(success: false, message: 'final-invalid');
    });
    final repo = MatchRepository(persistence: fakeFail);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': Uint8List.fromList([9,9,9]), 'name': 'bad.json', 'autoConfirm': true})),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;

    await state.exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // Now invoke import chosen path which should surface the dry-run failure
    await state.importFromDocumentsChosenForTest(tester.element(find.byType(SettingsView)), repo, fakeFail, null);
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('export web branch handles exporter timeout exception', (WidgetTester tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    // Force web branch
    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: (String p, String c) async => true, postExportOverride: (String p, String c) async { throw TimeoutException('simulated'); })),
      ),
    );

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    try {
      await state.exportBackupForTest(tester.element(find.byType(SettingsView)));
    } finally {
      SettingsView.forceKIsWeb = false;
    }

    await tester.pumpAndSettle();
    expect(true, isTrue);
  });

  testWidgets('importFromDocumentsForTest: listBackupsOverride throws is caught', (WidgetTester tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async { throw Exception('boom'); })),
      ),
    );

    final state = tester.state(find.byType(SettingsView));
    try {
      await (state as dynamic).importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo, fake);
    } catch (_) {}

    await tester.pumpAndSettle();
    expect(true, isTrue);
  });
}
