import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

class _BadPersistence extends PersistenceService {
  _BadPersistence({super.prefs});
  @override
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    throw Exception('simulated save failure');
  }
}

void main() {
  testWidgets('Import dry-run fails on invalid JSON via pickBackupOverride', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pick() async => {
      'bytes': Uint8List.fromList('not json'.codeUnits),
      'name': 'bad.json',
      'autoConfirm': true,
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pick)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  // Expect validation failure SnackBar
  expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('Import via listBackupsOverride and readFileBytesOverride flow', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Prepare a minimal valid backup
    await svc.saveList('stages', [ {'stage': 1, 'scoringShoots': 5} ]);
    await svc.saveList('shooters', [ {'name': 'Bob', 'scaleFactor': 1.0} ]);
    await svc.saveList('stageResults', [ {'stage': 1, 'shooter': 'Bob', 'time': 5.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);

    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    final fake = _FakeFile('/tmp/fake_backup.json');

    Future<List<dynamic>> listBackups() async => [fake];
    Future<Uint8List> readFileBytes(String path) async => Uint8List.fromList((await svc.exportBackupJson()).codeUnits);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: listBackups, readFileBytesOverride: readFileBytes)),
      ),
    );

    await tester.pumpAndSettle();

    // Tap import and select the only option in the SimpleDialog
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // The dialog shows the filename (last path segment)
    expect(find.text('fake_backup.json'), findsOneWidget);
    await tester.tap(find.text('fake_backup.json'));
    await tester.pumpAndSettle();

    // Confirm dialog appears; tap Restore
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

  expect(find.textContaining('Import successful'), findsWidgets);
  });

  testWidgets('Import shows dialog and Cancel prevents restore', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    final bytes = Uint8List.fromList((await svc.exportBackupJson()).codeUnits);

    Future<Map<String, dynamic>?> pick() async => {
      'bytes': bytes,
      'name': 'confirm_backup.json',
      // no autoConfirm so dialog appears
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pick)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Confirm dialog should be present
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // No success message should be shown
    expect(find.textContaining('Import successful'), findsNothing);
  });

  testWidgets('Import failure during persist shows Import failed', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final goodPrefs = await SharedPreferences.getInstance();
    final goodSvc = PersistenceService(prefs: goodPrefs);
    // prepare good backup bytes
    await goodSvc.saveList('stages', [ {'stage': 1, 'scoringShoots': 3} ]);
    await goodSvc.saveList('shooters', [ {'name': 'Eve', 'scaleFactor': 1.0} ]);
    await goodSvc.saveList('stageResults', [ {'stage': 1, 'shooter': 'Eve', 'time': 3.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);
    final bytes = Uint8List.fromList((await goodSvc.exportBackupJson()).codeUnits);

    // repo that uses the bad persistence instance
  final badPrefs = await SharedPreferences.getInstance();
  final badSvc = _BadPersistence(prefs: badPrefs);
    final repo = MatchRepository(persistence: badSvc);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pick() async => {
      'bytes': bytes,
      'name': 'bad_save.json',
      'autoConfirm': true,
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pick)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  expect(find.textContaining('Import failed'), findsWidgets);
  });

  testWidgets('Export shows Export failed when exporter throws', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    Future<void> badSave(String path, String content) async {
      throw Exception('simulated exporter error');
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: badSave)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

  expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('Import shows no-backups SnackBar when listBackupsOverride returns empty', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    Future<List<dynamic>> emptyList() async => [];

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: emptyList)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  expect(find.textContaining('No backup files found'), findsWidgets);
  });

  testWidgets('Import error shown when readFileBytesOverride throws', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    final fake = _FakeFile('/tmp/failure.json');
    Future<List<dynamic>> listBackups() async => [fake];
    Future<Uint8List> badRead(String path) async => throw Exception('simulated read error');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: listBackups, readFileBytesOverride: badRead)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  // Select the file from the dialog to trigger the read (which throws)
  expect(find.text('failure.json'), findsOneWidget);
  await tester.tap(find.text('failure.json'));
  await tester.pumpAndSettle();

  // After selecting the file, read should throw and the catch should show an Import error
  expect(find.textContaining('Import error'), findsWidgets);
  });

  testWidgets('Export with pickBackupOverride null shows No file selected', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pickNull() async => null;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickNull)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

  expect(find.text('No file selected'), findsWidgets);
  });

  testWidgets('Export pickBackupOverride with invalid JSON shows Backup validation failed', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pickBad() async => {
      'bytes': Uint8List.fromList('badjson'.codeUnits),
      'name': 'bad.json',
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickBad)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

  expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('Export pickBackupOverride autoConfirm true triggers import successful', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Prepare a valid backup
    await svc.saveList('stages', [ {'stage': 1, 'scoringShoots': 5} ]);
    await svc.saveList('shooters', [ {'name': 'Zed', 'scaleFactor': 1.0} ]);
    await svc.saveList('stageResults', [ {'stage': 1, 'shooter': 'Zed', 'time': 1.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);

    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    final bytes = Uint8List.fromList((await svc.exportBackupJson()).codeUnits);

    Future<Map<String, dynamic>?> pickAuto() async => {
      'bytes': bytes,
      'name': 'auto.json',
      'autoConfirm': true,
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickAuto)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Export Backup'));
  await tester.pumpAndSettle();

  // Confirm the restore dialog that appears in the export path
  expect(find.text('Confirm restore'), findsOneWidget);
  await tester.tap(find.text('Restore'));
  await tester.pumpAndSettle();

  expect(find.textContaining('Import successful'), findsWidgets);
  });
}
