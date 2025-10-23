import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('pickBackupOverride returns null -> No file selected', (tester) async {
    final fakePersistence = FakePersistence();
    final repo = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(pickBackupOverride: () async => null),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No file selected'), findsWidgets);
  });

  testWidgets('listBackupsOverride empty -> No backup files found', (tester) async {
    final fakePersistence = FakePersistence();
    final repo = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(listBackupsOverride: () async => []),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No backup files found'), findsWidgets);
  });

  testWidgets('pickBackupOverride autoConfirm false -> user cancels confirm dialog', (tester) async {
    final bytes = Uint8List.fromList([1,2,3]);
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages':1,'shooters':1,'stageResults':1});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'cancel.json', 'autoConfirm': false}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Confirm dialog should appear; press Cancel
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    expect(cancel, findsOneWidget);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    // Since user canceled, no Import successful or failed messages should appear; check status hasn't changed to 'Import successful'
    expect(find.textContaining('Import successful'), findsNothing);
  });
}
