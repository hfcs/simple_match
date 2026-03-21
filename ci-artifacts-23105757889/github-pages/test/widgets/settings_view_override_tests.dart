import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

// Test-only repo that throws when loadAll() is called to exercise reload-failure paths
class RepoThrow extends MatchRepository {
  RepoThrow({super.persistence});
  @override
  Future<void> loadAll() async => throw Exception('boom');
}

void main() {
  testWidgets('export override called with expected content', (tester) async {
    final fakePersistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fakePersistence);

    String? savedPath;
    String? savedContent;
    Future<void> saveExport(String path, String content) async {
      savedPath = path;
      savedContent = content;
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: saveExport)),
      ),
    );

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(savedPath, isNotNull);
    expect(savedContent, contains('"ok":true'));
  });

  testWidgets('import list override shows file name', (tester) async {
    final fakePersistence = FakePersistence();
    final repo = MatchRepository(persistence: fakePersistence);

    final fileObj = _FakeFile('/tmp/test.json');
    Future<List<dynamic>> listOverride() async => [fileObj];
    Future<Uint8List> readOverride(String path) async => Uint8List.fromList(utf8.encode('{}'));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: listOverride, readFileBytesOverride: readOverride)),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('test.json'), findsOneWidget);
  });

  testWidgets('cancelling import from list does not perform import', (tester) async {
    bool importCalled = false;
    final fakePersistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (!dryRun) importCalled = true;
      return FakeImportResult(success: true, message: 'ok', counts: {});
    });
    final repo = MatchRepository(persistence: fakePersistence);

    final fileObj = _FakeFile('/tmp/test.json');
    Future<List<dynamic>> listOverride() async => [fileObj];
    Future<Uint8List> readOverride(String path) async => Uint8List.fromList(utf8.encode('{}'));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: listOverride, readFileBytesOverride: readOverride)),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('test.json'));
    await tester.pump(const Duration(milliseconds: 200));

  // Confirmation dialog should appear — press Cancel
  // SettingsView shows 'Confirm restore' as the dialog title
  expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(importCalled, isFalse, reason: 'Import should not be called when user cancels');
  });

  testWidgets('pickBackupOverride with autoConfirm true performs import and reloads repo', (tester) async {
    bool importCalled = false;
    final fakePersistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (!dryRun) importCalled = true;
      return FakeImportResult(success: true, message: 'ok', counts: {'stages': 1, 'shooters': 1, 'stageResults': 0});
    });
    final repo = MatchRepository(persistence: fakePersistence);

    Future<Map<String, dynamic>?> pickOverride() async => {
          'bytes': Uint8List.fromList(utf8.encode('{}')),
          'name': 'picked.json',
          'autoConfirm': true,
        };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickOverride)),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should show status text updated after successful import
    expect(find.text('Status: Import successful'), findsOneWidget);
    expect(importCalled, isTrue);
  });

  testWidgets('pickBackupOverride dry-run failure shows validation error', (tester) async {
    final fakePersistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'corrupt', counts: {});
      return FakeImportResult(success: true, message: 'ok', counts: {});
    });
    final repo = MatchRepository(persistence: fakePersistence);

    Future<Map<String, dynamic>?> pickOverride() async => {
          'bytes': Uint8List.fromList(utf8.encode('{}')),
          'name': 'bad.json',
          'autoConfirm': true,
        };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickOverride)),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Dry-run failed — a SnackBar with validation message should be shown
    expect(find.text('Backup validation failed: corrupt'), findsOneWidget);
  });

  testWidgets('import succeeds but repo.loadAll throws shows reload-failed status', (tester) async {
    bool importCalled = false;
    final fakePersistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (!dryRun) importCalled = true;
      return FakeImportResult(success: true, message: 'ok', counts: {});
    });

    final repo = RepoThrow(persistence: fakePersistence);

    Future<Map<String, dynamic>?> pickOverride() async => {
          'bytes': Uint8List.fromList(utf8.encode('{}')),
          'name': 'picked.json',
          'autoConfirm': true,
        };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickOverride)),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(importCalled, isTrue);
    // SettingsView sets a status indicating reload failed
    expect(find.textContaining('Import succeeded, reload failed'), findsOneWidget);
  });

  testWidgets('pickBackupOverride with autoConfirm false and user cancels does not import', (tester) async {
    bool importCalled = false;
    final fakePersistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (!dryRun) importCalled = true;
      return FakeImportResult(success: true, message: 'ok', counts: {});
    });
    final repo = MatchRepository(persistence: fakePersistence);

    Future<Map<String, dynamic>?> pickOverride() async => {
          'bytes': Uint8List.fromList(utf8.encode('{}')),
          'name': 'picked.json',
          // no autoConfirm key => should show dialog and we will cancel
        };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickOverride)),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog should be shown; press Cancel
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(importCalled, isFalse);
  });

  testWidgets('saveExportOverride throwing shows export-failed status', (tester) async {
    final fakePersistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fakePersistence);

    Future<void> saveExport(String path, String content) async {
      throw Exception('disk full');
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: saveExport)),
      ),
    );

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should display both a status line and a SnackBar with the export-failed message
    expect(find.text('Status: Export failed: Exception: disk full'), findsOneWidget);
    expect(find.text('Export failed: Exception: disk full'), findsOneWidget);
  });
}
