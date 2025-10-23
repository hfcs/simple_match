import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFile2 {
  final String path;
  _FakeFile2(this.path);
}

void main() {
  testWidgets('pickBackupOverride confirm dialog then import success', (tester) async {
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'webfile.json', 'autoConfirm': false},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Confirm restore dialog appears
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful')), findsWidgets);
  });

  testWidgets('pickBackupOverride with dry-run failure shows validation message', (tester) async {
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': Uint8List.fromList([1]), 'name': 'bad.json'},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Backup validation failed')), findsWidgets);
  });

  testWidgets('saveExportOverride throwing still shows export message', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (name, content) async {
              throw Exception('boom');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Export')), findsWidgets);
  });

  testWidgets('listBackupsOverride with multiple files and choose second then cancel confirm', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    final f1 = _FakeFile2('/tmp/a.json');
    final f2 = _FakeFile2('/tmp/b.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [f1, f2],
            readFileBytesOverride: (p) async => Uint8List.fromList([1, 2]),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // dialog present
    expect(find.text('Select backup to import'), findsOneWidget);
    // choose the second item - its label is 'b.json'
    await tester.tap(find.text('b.json'));
    await tester.pumpAndSettle();

    // Confirm dialog appears, then cancel
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Ensure Status text exists but no 'Import successful'
    expect(find.textContaining('Status:'), findsOneWidget);
    expect(find.text('Status: Import successful'), findsNothing);
  });

  testWidgets('readFileBytesOverride throws while choosing file shows Import error', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    final f1 = _FakeFile2('/tmp/fail.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [f1],
            readFileBytesOverride: (p) async => throw Exception('read fail'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fail.json'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import error')), findsWidgets);
  });
}
