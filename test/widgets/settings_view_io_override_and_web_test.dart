import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Export backup uses saveExportOverride and shows status', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    String? exportedName;
    String? exportedContent;

    Future<void> saver(String name, String content) async {
      exportedName = name;
      exportedContent = content;
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          saveExportOverride: saver,
        ),
      ),
    ));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The override should have been called and a status message shown.
    expect(exportedName, isNotNull);
    expect(exportedContent, contains('"ok":true'));
    expect(find.textContaining('Exported via override as'), findsWidgets);
  });

  testWidgets('Import with pickBackupOverride returning null shows No file selected', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          pickBackupOverride: () async => null,
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No file selected'), findsOneWidget);
  });

  testWidgets('Import via web with autoConfirm true performs import and shows success', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    Future<Map<String, Object>> pick() async => {'bytes': Uint8List.fromList([1, 2, 3]), 'name': 'b.json', 'autoConfirm': true};

    final prev = SettingsView.forceKIsWeb;
    SettingsView.forceKIsWeb = true;
    try {
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            pickBackupOverride: pick,
          ),
        ),
      ));

      await tester.tap(find.text('Import Backup'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Import successful'), findsWidgets);
    } finally {
      SettingsView.forceKIsWeb = prev;
    }
  });

  testWidgets('ImportFromDocuments shows No backup files found when list is empty', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          listBackupsOverride: () async => [],
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Wait again to ensure any SnackBar or status text is visible, then
    // assert using a contains matcher for robustness.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('No backup files found'), findsOneWidget);
  });
}
