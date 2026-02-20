import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Import handles final import failure and shows Import failed', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: false, message: 'final bad');
    });

    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => {'bytes': Uint8List.fromList([9, 9]), 'name': 'bad.json', 'autoConfirm': true}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import failed'), findsWidgets);
  });

  testWidgets('Export saveExportOverride throwing shows Export failed', (tester) async {
    final fakePersistence = FakePersistence(exportJsonValue: '{}');
    final repo = MatchRepository(persistence: fakePersistence);

    Future<void> throwingSaver(String path, String content) async {
      throw StateError('save failed');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(saveExportOverride: throwingSaver),
      ),
    ));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('pickBackupOverride without autoConfirm and Cancel returns early', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => {'bytes': Uint8List.fromList([7, 7, 7]), 'name': 'c.json'}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Confirm dialog should appear; tap Cancel
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should not show Import successful
    expect(find.textContaining('Import successful'), findsNothing);
  });

  testWidgets('pickBackupOverride returning null shows No file selected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => null)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No file selected'), findsOneWidget);
  });

  testWidgets('pickBackupOverride dry-run failure shows validation SnackBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid');
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'bad.json'})),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Backup validation failed')), findsOneWidget);
  });

  testWidgets('import non-dry-run failure shows Import failed message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true);
      return FakeImportResult(success: false, message: 'bad import');
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'bad2.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('Status: Import failed')), findsOneWidget);
  });

  testWidgets('listBackupsOverride empty shows No backup files found message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async => [])),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Allow any delayed UI updates (SnackBar/status label) to settle, then
    // assert using a contains-style matcher to avoid brittle exact-text checks.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('No backup files found'), findsOneWidget);
  });
}
 
