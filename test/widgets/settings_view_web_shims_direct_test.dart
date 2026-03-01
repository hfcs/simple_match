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
  testWidgets('direct exportViaWebForTest updates status and calls exporter', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: SettingsView()),
      ),
    );
    await tester.pumpAndSettle();

    // Access the state and call the test shim directly.
    final state = tester.state(find.byType(SettingsView)) as dynamic;
    // Provide a simple exporter that records calls.
    var called = false;
    Future<void> exporter(String name, String json) async {
      called = true;
      return;
    }

  await state.exportViaWebForTest(tester.element(find.byType(SettingsView)), fake, exporter, 'ts-test');
  await tester.pumpAndSettle();
  expect(called, isTrue);
  // The public status text should contain the exported message.
  expect(find.textContaining('Status: Exported to browser download'), findsOneWidget);
  });

  testWidgets('direct importViaWebForTest handles repo.loadAll throwing', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}', importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages':0,'shooters':0,'stageResults':0}, message: null);
      return FakeImportResult(success: true, counts: {'stages':0,'shooters':0,'stageResults':0}, message: null);
    });

    final repo = _FailingLoadRepo(persistence: fake);

    // Provide a pickBackupOverride so _importViaWeb uses the provided bytes
    Future<Map<String, dynamic>?> pick() async {
      return {
        'bytes': Uint8List.fromList((await fake.exportBackupJson()).codeUnits),
        'name': 'test_backup.json',
        'autoConfirm': true,
      };
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pick)),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call importViaWebForTest and expect the reload-failure message to be shown
  await state.importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);
  await tester.pumpAndSettle();
  expect(find.textContaining('Status: Import succeeded, reload failed'), findsOneWidget);
  });
}
