import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _FailingLoadRepo extends MatchRepository {
  _FailingLoadRepo({PersistenceService? persistence}) : super(persistence: persistence);

  @override
  Future<void> loadAll() async {
    throw Exception('simulated loadAll failure');
  }
}

void main() {
  testWidgets('Import succeeds but repo.loadAll() throws is handled', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Prepare an export payload to import
    // Add some minimal data into prefs via saveList
    await svc.saveList('stages', [ {'stage': 1, 'scoringShoots': 5} ]);
    await svc.saveList('shooters', [ {'name': 'Alice', 'scaleFactor': 1.0} ]);
    await svc.saveList('stageResults', [ {'stage': 1, 'shooter': 'Alice', 'time': 10.0, 'a': 1, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0} ]);

    final jsonBytes = Uint8List.fromList((await svc.exportBackupJson()).codeUnits);

    // Repo that will throw on loadAll
    final repo = _FailingLoadRepo(persistence: svc);

    // Inject a pickBackupOverride that returns the bytes and autoConfirm true
    Future<Map<String, dynamic>?> pick() async => {
      'bytes': jsonBytes,
      'name': 'test_backup.json',
      'autoConfirm': true,
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pick)),
      ),
    );

    await tester.pumpAndSettle();
    final importButton = find.text('Import Backup');
    expect(importButton, findsOneWidget);

    await tester.tap(importButton);
    await tester.pumpAndSettle();

    // Expect a SnackBar mentioning reload failure
    expect(find.textContaining('Import succeeded but failed to reload repository'), findsOneWidget);
  });
}
