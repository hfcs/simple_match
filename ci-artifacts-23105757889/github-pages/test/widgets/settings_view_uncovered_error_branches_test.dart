import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Import/export error branches: dry-run fail, full-import fail, empty docs', (tester) async {
    // Keep snackbars suppressed so tests don't hang on timers.
    SettingsView.suppressSnackBarsInTests = true;

    // 1) Dry-run failure on pickBackupOverride during exportBackupForTest
    final fakeDryFail = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid backup');
      return FakeImportResult(success: true);
    });
    final repo1 = MatchRepository(persistence: fakeDryFail);
    await repo1.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo1,
        child: SettingsView(pickBackupOverride: () async {
          return {'bytes': Uint8List.fromList([1, 2, 3]), 'name': 'bad.json', 'autoConfirm': true};
        }),
      ),
    ));

    await tester.pumpAndSettle();

    final state1 = tester.state(find.byType(SettingsView));
    // Call exportBackupForTest which will use pickBackupOverride branch and dry-run should fail
    await tester.runAsync(() async {
      await (state1 as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });

    await tester.pumpAndSettle();
    expect(find.textContaining('Backup validation failed'), findsOneWidget);

    // 2) Full import failure path via importFromDocumentsConfirmedForTest
    final fakeFullFail = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: false, message: 'restore failed');
    });
    final repo2 = MatchRepository(persistence: fakeFullFail);
    await repo2.loadAll();

    // Create a fake chosen file-like object with a .path
    final chosen = _FakeFile('/tmp/simple_match_test_chosen.json');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo2,
        child: SettingsView(readFileBytesOverride: (path) async => Uint8List.fromList([4, 5, 6])),
      ),
    ));

    await tester.pumpAndSettle();
    final state2 = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state2 as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo2, fakeFullFail, chosen);
    });

    await tester.pumpAndSettle();
    expect(find.textContaining('Import failed'), findsOneWidget);

    // 3) Empty documents list branch for importFromDocumentsForTest
    final fakeEmpty = FakePersistence();
    final repo3 = MatchRepository(persistence: fakeEmpty);
    await repo3.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo3,
        child: SettingsView(listBackupsOverride: () async => []),
      ),
    ));

    await tester.pumpAndSettle();
    final state3 = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state3 as dynamic).importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo3, fakeEmpty);
    });

    await tester.pumpAndSettle();
    // No exception should be thrown; SnackBar is suppressed in tests so
    // we don't assert on SnackBar text here.

    // Restore flag
    SettingsView.suppressSnackBarsInTests = false;
  }, timeout: const Timeout(Duration(seconds: 60)));
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}
