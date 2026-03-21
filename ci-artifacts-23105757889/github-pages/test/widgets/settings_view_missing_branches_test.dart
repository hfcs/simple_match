// dart:typed_data not required here; removed to satisfy analyzer

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exportBackup failure when documentsDirOverride throws', (tester) async {
    final svc = FakePersistence(exportJsonValue: '{}');
    final repo = MatchRepository(persistence: svc);

    SettingsView.suppressSnackBarsInTests = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            documentsDirOverride: () async => throw Exception('no-docs'),
          ),
        ),
      ),
    );

    final settingsState = tester.state(find.byType(SettingsView)) as dynamic;

    await tester.runAsync(() => settingsState.exportBackupForTest(tester.element(find.byType(SettingsView))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsWidgets);

    SettingsView.suppressSnackBarsInTests = false;
  });

  testWidgets('importFromDocuments shows no backups when listBackupsOverride empty', (tester) async {
    final svc = FakePersistence();
    final repo = MatchRepository(persistence: svc);

    SettingsView.suppressSnackBarsInTests = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            listBackupsOverride: () async => [],
          ),
        ),
      ),
    );

    final settingsState = tester.state(find.byType(SettingsView)) as dynamic;

    await tester.runAsync(() => settingsState.importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo, svc));
    await tester.pumpAndSettle();

    expect(find.textContaining('No backup files found in app documents directory'), findsOneWidget);

    SettingsView.suppressSnackBarsInTests = false;
  });

  testWidgets('importViaWeb returns when pickBackupOverride yields null', (tester) async {
    final svc = FakePersistence();
    final repo = MatchRepository(persistence: svc);

    SettingsView.suppressSnackBarsInTests = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            pickBackupOverride: () async => null,
          ),
        ),
      ),
    );

    final settingsState = tester.state(find.byType(SettingsView)) as dynamic;

    await tester.runAsync(() => settingsState.importViaWebForTest(tester.element(find.byType(SettingsView)), repo, svc));
    await tester.pumpAndSettle();

    expect(find.textContaining('No file selected'), findsOneWidget);

    SettingsView.suppressSnackBarsInTests = false;
  });
}
