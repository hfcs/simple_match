import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

// Small test-only repo that throws from loadAll() to exercise reload-failure paths.
class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({persistence}) : super(persistence: persistence);
  @override
  Future<void> loadAll() async => throw Exception('reload fail');
}

void main() {
  testWidgets('Dry-run validation failure path (web pick)', (tester) async {
    final bytes = Uint8List.fromList([9, 9, 9]);
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid schema');
      return FakeImportResult(success: false, message: 'should not reach');
    });

    final repo = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'bad.json', 'autoConfirm': true}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Should show validation failed message
    expect(find.textContaining('Backup validation failed'), findsOneWidget);
  });

  testWidgets('Import succeeds but repo.loadAll throws (web pick)', (tester) async {
    final bytes = Uint8List.fromList([7, 7, 7]);
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final throwingRepo = _ThrowingRepo(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: throwingRepo,
      child: MaterialApp(
        home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'ok.json', 'autoConfirm': true}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Should show the reload-failed SnackBar and setState message
    expect(find.textContaining('reload failed'), findsOneWidget);
  });

  testWidgets('IO documents-list path: import failed and catch(e) path', (tester) async {
    final bytes = Uint8List.fromList([8, 8, 8]);

    // First case: import returns success=false
    final fakePersistenceFail = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: false, message: 'broken content');
    });

    final repoFail = MatchRepository(persistence: fakePersistenceFail);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repoFail,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [ _FakeFile('/tmp/b.json') ],
          readFileBytesOverride: (p) async => bytes,
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Choose the file
    await tester.tap(find.text('b.json'));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.widgetWithText(TextButton, 'Restore'));
    await tester.pumpAndSettle();

  // Could show both a SnackBar and the Status: text — accept one or more matches.
  expect(find.textContaining('Import failed:'), findsWidgets);

    // Second case: readFileBytes throws leading to catch(e) branch
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });
    final repo2 = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo2,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [ _FakeFile('/tmp/c.json') ],
          readFileBytesOverride: (p) async => throw Exception('io fail'),
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  await tester.tap(find.text('c.json'));
  await tester.pumpAndSettle();

  // readFileBytesOverride throws, so no confirm dialog will appear — expect the catch(e) path
  expect(find.textContaining('Import error:'), findsWidgets);
  });
}
