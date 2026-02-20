import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFileObj {
  final String path;
  _FakeFileObj(this.path);
}

class ThrowingRepo extends MatchRepository {
  ThrowingRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('reload boom');
  }
}

void main() {
  testWidgets('Import via web without autoConfirm: final import failure sets Import failed status', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: false, message: 'final fail');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    // Provide a pickBackupOverride that returns bytes and does NOT set autoConfirm
    Future<Map<String, dynamic>?> pickBackup() async => {
      'bytes': Uint8List.fromList([1, 2, 3]),
      'name': 'web_backup.json',
    };

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: pickBackup),
      ),
    ));
    await tester.pump();

    // Trigger import flow which will show a confirmation dialog; press Restore
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

  // Final result should show import failed status text in the Status line
  expect(find.textContaining('Status: Import failed'), findsOneWidget);
  });

  testWidgets('Import from documents: confirm dialog and repo.loadAll throws -> reload failed status', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = ThrowingRepo(persistence: fake);
    // Do not await loadAll on throwing repo

    Future<List<dynamic>> listBackups() async => [ _FakeFileObj('/tmp/confirm_backup.json') ];
    Future<Uint8List> readBytes(String path) async => Uint8List.fromList([1,2,3]);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(listBackupsOverride: listBackups, readFileBytesOverride: readBytes),
      ),
    ));
    await tester.pump();

    // Tap Import Backup -> choose file from SimpleDialog
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The file name should be shown in the SimpleDialog options
    expect(find.text('confirm_backup.json'), findsOneWidget);
    await tester.tap(find.text('confirm_backup.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // An AlertDialog confirm should appear; press Restore to proceed
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    // Because repo.loadAll throws, UI should show reload failed status
    expect(find.textContaining('reload failed'), findsOneWidget);
  });

  testWidgets('importFromDocumentsChosenForTest: final import failure via chosen file sets Import failed status', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: false, message: 'chosen fail');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<Uint8List> readBytes(String path) async => Uint8List.fromList([9,9,9]);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: readBytes),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    final chosen = _FakeFileObj('/tmp/chosen.json');

    // Call the chosen-for-test variant which will show a confirmation dialog.
    // The widget test can then interact with the dialog by tapping 'Restore'.
    final call = (state as dynamic).importFromDocumentsChosenForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog should be visible; press Restore
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Status: Import failed'), findsOneWidget);

    await call;
  });
}
