import 'dart:typed_data';
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

class _LocalThrowingRepo extends MatchRepository {
  _LocalThrowingRepo({required super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('simulated reload failure');
  }
}

void main() {
  testWidgets('importViaWebForTest final import failure sets Import failed status', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: false, message: 'final-fail');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pick() async => {'bytes': payload, 'name': 'finalfail.json', 'autoConfirm': true};

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    final state = tester.state(find.byType(SettingsView));
    await (state as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import failed'), findsWidgets);
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import failed')), findsWidgets);
  });

  testWidgets('importViaWebForTest dialog Cancel returns without import', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pick() async => {'bytes': payload, 'name': 'cancel.json', 'autoConfirm': false};

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    final state = tester.state(find.byType(SettingsView));
    final future = (state as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);

    await tester.pump(const Duration(milliseconds: 200));
    // Dialog should be present
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    await future;

    // No Import successful message should be shown
    expect(find.textContaining('Import successful'), findsNothing);
  });

  testWidgets('importFromDocumentsChosenForTest final import failure shows Import failed', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: false, message: 'doc-final-fail');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    final chosen = _FakeFile('/tmp/simple_match_backup_test.json');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: (p) async => payload),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

  final state = tester.state(find.byType(SettingsView));
  // Start the import flow which will show a confirm dialog; interact with it
  final future = (state as dynamic).importFromDocumentsChosenForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
  await tester.pump(const Duration(milliseconds: 200));
  // Tap Restore to proceed with the actual import
  expect(find.text('Restore'), findsOneWidget);
  await tester.tap(find.text('Restore'));
  await tester.pump(const Duration(milliseconds: 200));
  await future;

  expect(find.textContaining('Import failed'), findsWidgets);
  });

  testWidgets('importFromDocumentsConfirmedForTest handles repo.loadAll throwing and shows reload-failed', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final throwingRepo = _LocalThrowingRepo(persistence: fake);

    final chosen = _FakeFile('/tmp/simple_match_backup_test.json');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: throwingRepo,
        child: SettingsView(readFileBytesOverride: (p) async => payload),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    final state = tester.state(find.byType(SettingsView));
    await (state as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), throwingRepo, fake, chosen);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('reload failed')), findsOneWidget);
  });

  testWidgets('exportBackupForTest with pickBackupOverride and repo.loadAll throwing shows reload-failed', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final throwingRepo = _LocalThrowingRepo(persistence: fake);

    Future<Map<String, dynamic>?> pick() async => {'bytes': payload, 'name': 'exportfail.json', 'autoConfirm': true};

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: throwingRepo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

  final state = tester.state(find.byType(SettingsView));
  // Start the export flow which will present a confirm dialog; interact
  // with it and then await the future.
  final future = (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.text('Restore'), findsOneWidget);
  await tester.tap(find.text('Restore'));
  await tester.pump(const Duration(milliseconds: 200));
  await future;

  expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('reload failed')), findsOneWidget);
  });

  testWidgets('exportBackupForTest with pickBackupOverride final import failure shows Import failed', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: false, message: 'export-final-fail');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pick() async => {'bytes': payload, 'name': 'exportfail2.json', 'autoConfirm': true};

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

  final state = tester.state(find.byType(SettingsView));
  final future = (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.text('Restore'), findsOneWidget);
  await tester.tap(find.text('Restore'));
  await tester.pump(const Duration(milliseconds: 200));
  await future;

  expect(find.textContaining('Import failed'), findsWidgets);
  });
}
