import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({required PersistenceService persistence}) : super(persistence: persistence);
  @override
  Future<void> loadAll() async {
    throw Exception('simulated load failure');
  }
}

class _FailingImportPersistence extends PersistenceService {
  _FailingImportPersistence({super.prefs});

  @override
  Future<ImportResult> importBackupFromBytes(Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
    // simulate successful dry-run when asked
  if (dryRun) return ImportResult(success: true, message: 'dry', counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
    // simulate a failure on real import
  return ImportResult(success: false, message: 'simulated import validation failed', counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
  }
}

class _FakeFsEntity {
  final String path;
  _FakeFsEntity(this.path);
}

void main() {
  testWidgets('Import succeeds but repo.loadAll throws shows reload failed message', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Create a valid backup bytes
    await svc.saveList('stages', [ {'stage': 1, 'scoringShoots': 1} ]);
    await svc.saveList('shooters', [ {'name': 'X', 'scaleFactor': 1.0} ]);
    await svc.saveList('stageResults', [ {'stage': 1, 'shooter': 'X', 'time': 1.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);

    final bytes = Uint8List.fromList((await svc.exportBackupJson()).codeUnits);

    // Use a repo whose loadAll() throws after import succeeds
    final throwingRepo = _ThrowingRepo(persistence: svc);

    Future<Map<String, dynamic>?> pickAuto() async => {
      'bytes': bytes,
      'name': 'good.json',
      'autoConfirm': true,
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: throwingRepo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickAuto)),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should show 'Import succeeded but failed to reload repository' message via SnackBar or status text
    expect(find.textContaining('reload failed'), findsWidgets);
  });

  testWidgets('ImportBackupFromBytes returns failure shows Import failed', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = _FailingImportPersistence(prefs: prefs);

    // Create a bytes blob that will dry-run ok but fail on actual import
    final goodSvc = PersistenceService(prefs: prefs);
    await goodSvc.saveList('stages', [ {'stage': 1, 'scoringShoots': 1} ]);
    await goodSvc.saveList('shooters', [ {'name': 'Y', 'scaleFactor': 1.0} ]);
    await goodSvc.saveList('stageResults', [ {'stage': 1, 'shooter': 'Y', 'time': 1.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);
    final bytes = Uint8List.fromList((await goodSvc.exportBackupJson()).codeUnits);

    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pickAuto() async => {
      'bytes': bytes,
      'name': 'will_fail.json',
      'autoConfirm': true,
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickAuto)),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import failed'), findsWidgets);
  });

  testWidgets('Import uses real readFileBytes for a temp file and restores', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Prepare a valid backup JSON bytes
    await svc.saveList('stages', [ {'stage': 2, 'scoringShoots': 4} ]);
    await svc.saveList('shooters', [ {'name': 'Temp', 'scaleFactor': 1.0} ]);
    await svc.saveList('stageResults', [ {'stage': 2, 'shooter': 'Temp', 'time': 2.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);

    final bytes = Uint8List.fromList((await svc.exportBackupJson()).codeUnits);

    final fake = _FakeFsEntity('/tmp/simple_backup.json');

    Future<List<dynamic>> listBackups() async => [fake];
    Future<Uint8List> readFileBytes(String path) async => bytes;

    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: listBackups, readFileBytesOverride: readFileBytes)),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog should list our file name
    expect(find.text('simple_backup.json'), findsOneWidget);
    await tester.tap(find.text('simple_backup.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // Confirm and restore
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import successful'), findsWidgets);
  });
}
