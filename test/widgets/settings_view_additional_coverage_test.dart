import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exportViaWebForTest sets status and calls exporter', (tester) async {
    final svc = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: svc);

    SettingsView.suppressSnackBarsInTests = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: const SettingsView(),
        ),
      ),
    );

    // get the state object
    final settingsState = tester.state(find.byType(SettingsView)) as dynamic;

    var calledName = '';
    var calledJson = '';

    Future<void> exporter(String name, String json) async {
      calledName = name;
      calledJson = json;
      return Future.value();
    }

    await tester.runAsync(() => settingsState.exportViaWebForTest(tester.element(find.byType(SettingsView)), svc, exporter, 'TS1'));
    await tester.pumpAndSettle();

    expect(calledName, contains('simple_match_backup_TS1.json'));
    expect(calledJson, contains('{"ok":true}'));
    expect(find.textContaining('Exported to browser download'), findsOneWidget);

    SettingsView.suppressSnackBarsInTests = false;
  });

  testWidgets('importViaWebForTest with autoConfirm true shows Import successful', (tester) async {
    // Fake import function: dryRun returns success with counts, real run returns success
    final svc = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) {
        return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 0});
      }
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: svc);

    SettingsView.suppressSnackBarsInTests = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            pickBackupOverride: () async => {
              'bytes': Uint8List.fromList([1, 2, 3]),
              'name': 'fake.json',
              'autoConfirm': true,
            },
          ),
        ),
      ),
    );

    final settingsState = tester.state(find.byType(SettingsView)) as dynamic;

    await tester.runAsync(() => settingsState.importViaWebForTest(tester.element(find.byType(SettingsView)), repo, svc));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsOneWidget);

    SettingsView.suppressSnackBarsInTests = false;
  });
}
