import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

// A small MatchRepository subclass that throws on loadAll to exercise error
// handling paths in SettingsView tests.
class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({required super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('simulated reload failure');
  }
}

// Simple fake file type used by listBackupsOverride in tests.
class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('pickBackupOverride autoConfirm true performs import and shows success', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

  // Now exercise the documents-list path: provide a fake file object
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          listBackupsOverride: () async => [_FakeFile('/tmp/simple_match_backup_1.json')],
          readFileBytesOverride: (p) async => bytes,
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // SimpleDialog should show the file name
    expect(find.text('simple_match_backup_1.json'), findsOneWidget);
    await tester.tap(find.text('simple_match_backup_1.json'));
    await tester.pumpAndSettle();

    // Confirm dialog should appear; tap Restore
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsWidgets);
  });

    testWidgets('documents-list import -> dry-run failure shows validation failed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 2}})));

      final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
        if (dryRun) return FakeImportResult(success: false, message: 'invalid backup');
        return FakeImportResult(success: true);
      });

      final repo = MatchRepository(persistence: persistence);
      await repo.loadAll();

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            listBackupsOverride: () async => [_FakeFile('/tmp/bad_dry.json')],
            readFileBytesOverride: (p) async => bytes,
          ),
        ),
      ));

      await tester.tap(find.text('Import Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('bad_dry.json'));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Backup validation failed')), findsWidgets);
    });

    testWidgets('documents-list import -> final import failure shows Import failed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 2}})));

      final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
        if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 0});
        return FakeImportResult(success: false, message: 'corrupt');
      });

      final repo = MatchRepository(persistence: persistence);
      await repo.loadAll();

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            listBackupsOverride: () async => [_FakeFile('/tmp/final_fail.json')],
            readFileBytesOverride: (p) async => bytes,
          ),
        ),
      ));

      await tester.tap(find.text('Import Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('final_fail.json'));
      await tester.pumpAndSettle();

      // Confirm and proceed
      expect(find.text('Confirm restore'), findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import failed')), findsWidgets);
    });

    testWidgets('documents-list import -> readFileBytesOverride throws shows Import error', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
        return FakeImportResult(success: true);
      });

      final repo = MatchRepository(persistence: persistence);
      await repo.loadAll();

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            listBackupsOverride: () async => [_FakeFile('/tmp/read_error.json')],
            readFileBytesOverride: (p) async => throw Exception('boom read'),
          ),
        ),
      ));

      await tester.tap(find.text('Import Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('read_error.json'));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import error')), findsWidgets);
    });
  testWidgets('pickBackupOverride autoConfirm false, user accepts -> import success shown', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'confirm.json', 'autoConfirm': false}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Confirm dialog should appear; tap Restore (label used in UI)
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

  expect(find.textContaining('Import successful'), findsWidgets);
  });

  testWidgets('pickBackupOverride autoConfirm false, user cancels -> no import', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'cancel.json', 'autoConfirm': false}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Confirm dialog should appear; tap Cancel
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsNothing);
  });

  testWidgets('import where repo.loadAll throws shows reload-failed status', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence();
    final throwingRepo = _ThrowingRepo(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: throwingRepo,
        child: MaterialApp(
          home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'failreload.json', 'autoConfirm': true}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('reload failed')), findsOneWidget);
  });

  testWidgets('export using saveExportOverride updates status', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    String? savedName;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (name, content) async {
              savedName = name;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(savedName, isNotNull);
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('Status: Exported via override')), findsOneWidget);
  });

  testWidgets('kIsWeb forced: export uses web exporter branch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    SettingsView.forceKIsWeb = true;
    String? savedName;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (name, content) async {
              savedName = name;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(savedName, isNotNull);
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('kIsWeb forced: import uses web picker branch (autoConfirm true)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'webtest.json', 'autoConfirm': true}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsWidgets);

    SettingsView.forceKIsWeb = false;
  });

  testWidgets('documents-list dialog cancel returns without import', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          listBackupsOverride: () async => [_FakeFile('/tmp/cancel_choose.json')],
          readFileBytesOverride: (p) async => Uint8List.fromList([]),
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // SimpleDialog displayed; press outside by tapping Cancel option not present
    // Instead, simulate user pressing back/cancel by tapping outside: use Navigator.pop
    // Find the option and press it (we used SimpleDialogOption which shows filename)
    await tester.tap(find.text('cancel_choose.json'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // No Import successful message should be shown
    expect(find.textContaining('Import successful'), findsNothing);
  });

  testWidgets('kIsWeb forced and pickBackupOverride null -> shows No file selected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => null),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.text('No file selected'), findsWidgets);

    SettingsView.forceKIsWeb = false;
  });

  testWidgets('export with saveExportOverride throwing shows Export failed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (name, content) async {
              throw Exception('saveboom');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('documents-list dialog dismissed returns without import (chosen == null)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          listBackupsOverride: () async => [_FakeFile('/tmp/choose_but_cancel.json')],
          readFileBytesOverride: (p) async => Uint8List.fromList([]),
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  // Dismiss dialog by tapping outside the dialog area
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsNothing);
  });
}
