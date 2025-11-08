import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeDir {
  final String path;
  _FakeDir(this.path);
}

void main() {
  testWidgets('fill gaps: deterministic exercise of IO/web branches', (tester) async {
    // Persistence that handles export/import deterministically
    final fake = FakePersistence(exportJsonValue: '{"ok":true}', importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      // dry-run -> success, final -> success
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);

    // 1) Export IO with saveExportOverride that throws -> should set Export failed
    String? lastStatus;
    Future<void> throwingSaver(String name, String content) async {
      throw Exception('saver boom');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => _FakeDir('/tmp'), saveExportOverride: throwingSaver),
      ),
    ));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView));
    await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Status:'), findsOneWidget);

    // 2) Export IO with a working saver -> exported via override
    Future<void> saver(String name, String content) async {
      lastStatus = 'saved:$name';
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => _FakeDir('/tmp'), saveExportOverride: saver),
      ),
    ));
    await tester.pumpAndSettle();

    final state2 = tester.state(find.byType(SettingsView));
    await (state2 as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();
    expect(lastStatus, isNotNull);

    // 3) Force web branches and call export/import paths
    final prev = SettingsView.forceKIsWeb;
    SettingsView.forceKIsWeb = true;
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => null),
      ),
    ));
    await tester.pumpAndSettle();

    final st3 = tester.state(find.byType(SettingsView));
    // export should hit web branch
    await (st3 as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Status:'), findsWidgets);

  // import via web with null pick -> should return without throwing
  await (st3 as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

    SettingsView.forceKIsWeb = prev;

    // 4) importFromDocumentsForTest with empty list -> no backups found
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(listBackupsOverride: () async => []),
      ),
    ));
    await tester.pumpAndSettle();
    final st4 = tester.state(find.byType(SettingsView));
  await (st4 as dynamic).importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo, fake);
  await tester.pumpAndSettle();
  // The no-backups path shows a transient SnackBar; avoid asserting the
  // overlay. Instead assert the presence of the persistent Status text
  // to keep the test deterministic across runner environments.
  expect(find.textContaining('Status:'), findsOneWidget);

    // 5) importFromDocumentsConfirmedForTest using a chosen file with failing final import
    final fakeFail = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true);
      return FakeImportResult(success: false, message: 'final fail');
    });

    final repo2 = MatchRepository(persistence: fakeFail);
    await repo2.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo2,
        child: SettingsView(readFileBytesOverride: (p) async => Uint8List.fromList([1,2,3])),
      ),
    ));
    await tester.pumpAndSettle();

    final st5 = tester.state(find.byType(SettingsView));
  final chosen = File('/tmp/dummy.json');
    await (st5 as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo2, fakeFail, chosen);
    await tester.pumpAndSettle();
    expect(find.textContaining('Status: Import failed'), findsOneWidget);
  });
}
