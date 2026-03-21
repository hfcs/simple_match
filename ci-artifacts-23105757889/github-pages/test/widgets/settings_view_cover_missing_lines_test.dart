import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exportBackup _exportViaWeb call site executed when forced web', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    // Force web branches in VM tests
    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const SettingsView(),
      ),
    ));

    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    // Call the export path which should hit the _exportViaWeb call site
    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });

    // Verify UI updated status text exists
    await tester.pump();
    expect(find.textContaining('Status:'), findsOneWidget);

    // Restore global flag
    SettingsView.forceKIsWeb = false;
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('exportBackup IO path executes exporter and mounted-check', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    // Create a temporary directory to act as documents dir
    final Directory tmp = (await tester.runAsync(() async {
      return await Directory.systemTemp.createTemp('simple_match_test_docs');
    })) as Directory;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => tmp),
      ),
    ));

    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });

    await tester.pump();
    expect(find.textContaining('Status:'), findsOneWidget);

    // cleanup
    await tester.runAsync(() async {
      await tmp.delete(recursive: true);
    });
  }, timeout: const Timeout(Duration(seconds: 30)));
}
