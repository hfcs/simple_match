import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _FailingLoadRepo extends MatchRepository {
  _FailingLoadRepo({super.persistence});

  @override
  Future<void> loadAll() async {
    throw Exception('simulated loadAll failure');
  }
}

void main() {
  testWidgets('Import succeeds but repo.loadAll() throws is handled', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create fake persistence and prepare bytes via exportBackupJson on the fake
    final fake = FakePersistence(exportJsonValue: '{"stages":[],"shooters":[{"name":"Alice","scaleFactor":1.0}],"stageResults":[]}');
    final jsonBytes = Uint8List.fromList((await fake.exportBackupJson()).codeUnits);

    // Repo that will throw on loadAll
    final repo = _FailingLoadRepo(persistence: fake);

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
