import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Web import flow: autoConfirm true and false', (tester) async {
    // Avoid touching platform SharedPreferences in widget tests.
    // This test is intended to run on the web device (flutter test -d chrome)
    final bytes = Uint8List.fromList([1, 2, 3]);

    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) {
        return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      }
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fakePersistence);
    repo.importMode = true;
    await repo.loadAll();

    // autoConfirm true -> should skip confirm dialog
    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: const MaterialApp(home: SettingsView(pickBackupOverride: null)),
    ));

    // Replace the widget with one that supplies pickBackupOverride returning autoConfirm
    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {'bytes': bytes, 'name': 'web.json', 'autoConfirm': true},
        ),
      ),
    ));

  // Tap Import Backup (tap the label text to avoid hit-test issues)
  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Expect status updated to 'Import successful' via setState
    expect(find.textContaining('Import successful'), findsWidgets);

    // Now test autoConfirm false -> dialog appears and we press Restore
    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {'bytes': bytes, 'name': 'web2.json', 'autoConfirm': false},
        ),
      ),
    ));

  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog should appear; tap Restore
    final restoreFinder = find.widgetWithText(TextButton, 'Restore');
    expect(restoreFinder, findsOneWidget);
    await tester.tap(restoreFinder);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import successful'), findsWidgets);
  });
}
