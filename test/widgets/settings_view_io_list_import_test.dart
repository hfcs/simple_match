import 'dart:typed_data';
// dart:io not required; avoid filesystem in tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({PersistenceService? persistence}) : super(persistence: persistence);

  @override
  Future<void> loadAll() async {
    throw StateError('simulated reload failure');
  }
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  testWidgets('IO list import handles reload failure and shows message', (tester) async {
    // Prepare a fake persistence that validates dry-run and returns success
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

  // Create a fake file-like object with a .path property for listBackups
  final fakeFile = _FakeFile('/tmp/simple_match_backup.json');
  final filesList = [fakeFile];

  final repo = _ThrowingRepo(persistence: fake);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            listBackupsOverride: () async => filesList,
            readFileBytesOverride: (path) async => Uint8List.fromList([1,2,3]),
          ),
        ),
      ),
    );

    // Tap the Import button
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  // The simple dialog should appear with our file; tap it
  expect(find.text(fakeFile.path.split('/').last), findsOneWidget);
  await tester.tap(find.text(fakeFile.path.split('/').last));
    await tester.pumpAndSettle();

    // Confirm dialog should appear; tap Restore
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    // Because loadAll() throws, expect a SnackBar or status message indicating reload failed
    expect(find.textContaining('reload failed'), findsWidgets);

  // No filesystem cleanup needed for fake file
  });

  testWidgets('IO documents listing import flow with SimpleDialog selection', (tester) async {
    final bytes = Uint8List.fromList([4, 5, 6]);

    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 2, 'shooters': 2, 'stageResults': 2});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fakePersistence);

    // Provide listBackupsOverride returning two fake files
    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [ _FakeFile('/tmp/simple_match_backup_1.json') , _FakeFile('/tmp/simple_match_backup_2.json') ],
          readFileBytesOverride: (path) async => bytes,
          documentsDirOverride: () async => null,
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // The SimpleDialog should appear with two options; tap the first option's text
    final option = find.text('simple_match_backup_1.json');
    expect(option, findsOneWidget);
    await tester.tap(option);
    await tester.pumpAndSettle();

    // Confirm dialog appears; tap Restore
    final restore = find.widgetWithText(TextButton, 'Restore');
    expect(restore, findsOneWidget);
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsWidgets);
  });
}
