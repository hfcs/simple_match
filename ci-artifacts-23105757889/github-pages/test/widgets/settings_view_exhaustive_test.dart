import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo(FakePersistence p): super(persistence: p);
  @override
  Future<void> loadAll() async { throw Exception('reload fail'); }
}

void main() {
  testWidgets('Exhaustive import scenarios', (tester) async {
    final payload = {'metadata': {'schemaVersion': 2}};
    final goodBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  // final badBytes not used

    // 1) pickBackupOverride returns null -> No file selected
    final fake1 = FakePersistence();
    final repo1 = MatchRepository(persistence: fake1);
  await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo1, child: SettingsView(pickBackupOverride: () async => null))));
  await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(value: repo1, child: MaterialApp(home: SettingsView(pickBackupOverride: () async => null))));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SnackBar), findsOneWidget);

    // 2) pickBackupOverride autoConfirm true -> good import success
    final fake2 = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1});
      return FakeImportResult(success: true);
    });
    final repo2 = MatchRepository(persistence: fake2);
  await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo2, child: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g.json', 'autoConfirm': true}))));
  await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(value: repo2, child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g.json', 'autoConfirm': true}))));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful')), findsWidgets);

    // 3) pickBackupOverride autoConfirm false -> show dialog -> cancel
    final fake3 = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1});
      return FakeImportResult(success: true);
    });
    final repo3 = MatchRepository(persistence: fake3);
  await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo3, child: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g2.json', 'autoConfirm': false}))));
  await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(value: repo3, child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g2.json', 'autoConfirm': false}))));
    await tester.pump(const Duration(milliseconds: 200));
    final before = find.textContaining('Import successful');
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    // dialog present
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));
    // ensure no new success SnackBar was shown (status text remains same or absent)
    final after = find.textContaining('Import successful');
    expect(after.evaluate().length <= before.evaluate().length, isTrue);

    // 4) pickBackupOverride autoConfirm false -> show dialog -> restore -> res.success false
    final fake4 = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1});
      return FakeImportResult(success: false, message: 'bad');
    });
    final repo4 = MatchRepository(persistence: fake4);
  await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo4, child: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g3.json', 'autoConfirm': false}))));
  await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(value: repo4, child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g3.json', 'autoConfirm': false}))));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import failed')), findsWidgets);

    // 5) pickBackupOverride -> res.success true but repo.loadAll throws
    final fake5 = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1});
      return FakeImportResult(success: true);
    });
    final repo5 = _ThrowingRepo(fake5);
  await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo5, child: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g4.json', 'autoConfirm': true}))));
  await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(value: repo5, child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': goodBytes, 'name': 'g4.json', 'autoConfirm': true}))));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('reload failed')), findsWidgets);

  }, timeout: const Timeout(Duration(seconds: 45)));
}
