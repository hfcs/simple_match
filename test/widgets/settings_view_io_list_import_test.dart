import 'dart:typed_data';
// dart:io not required; avoid filesystem in tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({super.persistence});

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
    SharedPreferences.setMockInitialValues({});
    SettingsView.suppressSnackBarsInTests = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Prepare a fake persistence that validates dry-run and returns success
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

  // Create a fake file-like object with a .path property for listBackups
  final fakeFile = _FakeFile('/tmp/simple_match_backup.json');

  final repo = _ThrowingRepo(persistence: fake);
  repo.importMode = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            // Use pickBackupOverride with autoConfirm to avoid dialogs
            pickBackupOverride: () async => <String, dynamic>{
              'bytes': Uint8List.fromList([1, 2, 3]),
              'name': fakeFile.path.split('/').last,
              'autoConfirm': true,
            },
          ),
        ),
      ),
    );

    // Tap Import Backup to invoke the override path
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Because loadAll() throws, expect a SnackBar or status message indicating reload failed
    expect(find.textContaining('reload failed'), findsWidgets);
    SettingsView.suppressSnackBarsInTests = false;

  // No filesystem cleanup needed for fake file
  });

  testWidgets('IO documents listing import flow with SimpleDialog selection', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final bytes = Uint8List.fromList([4, 5, 6]);

    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 2, 'shooters': 2, 'stageResults': 2});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fakePersistence);
    repo.importMode = true;
    SettingsView.suppressSnackBarsInTests = true;

    // Provide listBackupsOverride returning two fake files
    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => <String, dynamic>{
            'bytes': bytes,
            'name': 'simple_match_backup_1.json',
            'autoConfirm': true,
          },
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import successful'), findsWidgets);
    SettingsView.suppressSnackBarsInTests = false;
  });
}
