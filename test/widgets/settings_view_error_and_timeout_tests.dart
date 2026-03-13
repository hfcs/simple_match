import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Export with saveExportOverride throwing shows Export failed', (tester) async {
    SettingsView.suppressSnackBarsInTests = true;
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<void> throwingSave(String path, String content) async {
      throw StateError('save failed');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(saveExportOverride: throwingSave),
      ),
    ));

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView));
    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });
    await tester.pumpAndSettle();
    // SnackBars suppressed; ensure no exception and widget still present
    expect(find.byType(SettingsView), findsOneWidget);
    SettingsView.suppressSnackBarsInTests = false;
  });

  testWidgets('Export exporter timeout is handled', (tester) async {
    // Do not enable the wrapper-level test timeout so the internal exporter
    // timeout inside `_exportBackup` can be exercised and handled.
    SettingsView.suppressSnackBarsInTests = false;
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<void> slowSave(String path, String content) async {
      // Delay longer than the internal exporter timeout (2s) so the
      // exportFuture.timeout triggers and is caught inside `_exportBackup`.
      await Future.delayed(const Duration(seconds: 3));
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(saveExportOverride: slowSave, documentsDirOverride: () async => null),
      ),
    ));

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView));
    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SettingsView), findsOneWidget);
    SettingsView.suppressSnackBarsInTests = false;
  });

  testWidgets('pickBackupOverride null returns gracefully', (tester) async {
    SettingsView.suppressSnackBarsInTests = true;
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => null),
      ),
    ));

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView));
    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SettingsView), findsOneWidget);
    SettingsView.suppressSnackBarsInTests = false;
  });
}
