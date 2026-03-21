import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('pickBackupOverride returns null shows No file selected', (tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => null),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No file selected'), findsWidgets);
  });

  testWidgets('pickBackupOverride dry-run fails shows validation failed', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad backup');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => {'bytes': Uint8List.fromList([1]), 'name': 'x.json'}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('saveExportOverride used for export shows exported message', (tester) async {
    var called = false;
    Future<void> fakeSaver(String path, String content) async {
      called = true;
    }

    final repo = MatchRepository(persistence: FakePersistence(exportJsonValue: '{}'));

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(saveExportOverride: fakeSaver),
      ),
    ));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(called, isTrue);
    expect(find.textContaining('Exported via override'), findsWidgets);
  });
}
