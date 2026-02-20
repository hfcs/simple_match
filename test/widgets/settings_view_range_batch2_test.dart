import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Web pick override: autoConfirm true -> import successful', (tester) async {
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'w.json', 'autoConfirm': true})),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful')), findsWidgets);
  });

  testWidgets('Web pick override: dry-run validation fails (autoConfirm true with bad bytes)', (tester) async {
    final bad = Uint8List.fromList([9, 9]);
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bad, 'name': 'bad.json', 'autoConfirm': true})),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Backup validation failed')), findsWidgets);
  });

  testWidgets('pickBackupOverride returns null -> import cancelled path', (tester) async {
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async => FakeImportResult(success: true));
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => null)),
      ),
    );

  await tester.tap(find.text('Import Backup'));
  await tester.pump(const Duration(milliseconds: 200));

  // pickBackup returned null -> a SnackBar is shown with 'No file selected'
  expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Export saveOverride throws -> shows export failed', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: (p, s) async { throw Exception('saveboom'); })),
      ),
    );

  await tester.tap(find.text('Export Backup'));
  await tester.pump(const Duration(milliseconds: 200));

  expect(find.byType(SnackBar), findsOneWidget);
  });
}
