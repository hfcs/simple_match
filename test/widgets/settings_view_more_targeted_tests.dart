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
    expect(find.textContaining('Backup validation failed'), findsOneWidget);
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

    expect(find.textContaining('Import successful'), findsOneWidget);
  });
}
