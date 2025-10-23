import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    // Ensure we exercise web-only branches
    SettingsView.forceKIsWeb = true;
  });

  tearDown(() {
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('kIsWeb import: picked == null shows No file selected', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('No file selected')), findsWidgets);
  });

  testWidgets('kIsWeb import: autoConfirm true skips dialog and imports', (tester) async {
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 0});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'w.json', 'autoConfirm': true},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful')), findsWidgets);
  });

  testWidgets('kIsWeb import: autoConfirm false shows confirm dialog and user cancels', (tester) async {
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 2, 'shooters': 1, 'stageResults': 0});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'w2.json', 'autoConfirm': false},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // dialog should appear
    expect(find.text('Confirm restore'), findsOneWidget);
    // cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // After cancel, no Import successful message
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful')), findsNothing);
  });
}
