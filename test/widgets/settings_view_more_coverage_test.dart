import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'package:simple_match/views/settings_view.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

// Simple fake file object with a `.path` property used by SettingsView when
// listing backups from the documents directory.
class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  testWidgets('SettingsView export/import branches (overrides)', (WidgetTester tester) async {
    // Track calls
    String? exportedPath;
    String? exportedContent;

    // 1) successful export
    Future<void> saveExportSuccess(String path, String content) async {
      exportedPath = path;
      exportedContent = content;
    }

    // 2) failing export
    Future<Never> saveExportFail(String path, String content) async {
      throw Exception('disk full');
    }

    // 3) pick backup override returning a valid full backup JSON bytes and autoConfirm
    Future<Map<String, dynamic>> pickBackupOk() async => <String, dynamic>{
          'bytes': Uint8List.fromList('{"stages": [], "shooters": [], "stageResults": []}'.codeUnits),
          'name': 'demo.json',
          'autoConfirm': true,
        };

    // 5) listBackups + readFileBytes flow (simulate a file in documents dir)
    final fakeFilePath = '/tmp/fake.json';
    Future<List<_FakeFile>> listBackups() async => [ _FakeFile(fakeFilePath) ];
    Future<Uint8List> readFileBytes(String path) async => Uint8List.fromList('{"fromFile":1}'.codeUnits);

  // Build the SettingsView with a successful export override first
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
            create: (_) => MatchRepository(persistence: FakePersistence()),
            child: SettingsView(
              saveExportOverride: saveExportSuccess,
            ),
        ),
      ),
    );

    // Tap Export Backup button (label text used in SettingsView)
    expect(find.text('Export Backup'), findsOneWidget);
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

  expect(exportedPath, isNotNull);
  expect(exportedContent, isNotNull);

    // Now replace with failing export override and ensure SnackBar shows
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
            create: (_) => MatchRepository(persistence: FakePersistence()),
            child: SettingsView(
              saveExportOverride: saveExportFail,
            ),
        ),
      ),
    );

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    // SnackBar with 'Export failed' should be shown
    expect(find.textContaining('Export failed'), findsOneWidget);

    // Now test import with a valid backup via pickBackupOverride (autoConfirm=true)
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
            create: (_) => MatchRepository(persistence: FakePersistence()),
            child: SettingsView(
              pickBackupOverride: pickBackupOk,
            ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Should show success SnackBar
    expect(find.textContaining('Import successful'), findsOneWidget);

    // Now test import using listBackups + readFileBytes flow
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
            create: (_) => MatchRepository(persistence: FakePersistence()),
            child: SettingsView(
              listBackupsOverride: listBackups,
              readFileBytesOverride: readFileBytes,
            ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // The import flow should either present the file list and allow selecting
    // 'fake.json' (IO path), or on web it may use the browser picker / override
    // and immediately show a success SnackBar. Accept either outcome.
    final fileFinder = find.text('fake.json');
    final successFinder = find.textContaining('Import successful');
    if (fileFinder.evaluate().isNotEmpty) {
      expect(fileFinder, findsWidgets);
    } else {
      expect(successFinder, findsOneWidget);
    }
  });
}
