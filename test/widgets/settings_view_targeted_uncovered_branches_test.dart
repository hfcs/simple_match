import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    // Ensure test-only flags are in a known state
    SettingsView.suppressSnackBarsInTests = true;
    SettingsView.forceKIsWeb = false;
    SettingsView.pauseAfterImportForDebugger = false;
    SettingsView.forceExitAfterImportForDebugger = false;
  });

  testWidgets('exportViaWebForTest uses exporter and sets status', (tester) async {
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);

    String? gotName;
    String? gotJson;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView()),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).exportViaWebForTest(
        tester.element(find.byType(SettingsView)),
        persistence,
        (String name, String json) async {
          gotName = name;
          gotJson = json;
        },
        DateTime.now().toIso8601String().replaceAll(':', '-'),
      );
    });

    await tester.pumpAndSettle();

    expect(gotName, isNotNull);
    expect(gotJson, contains('ok'));
    expect(find.textContaining('Exported'), findsWidgets);
  });

  testWidgets('importViaWebForTest with no pick shows no-file path', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    // Temporarily allow SnackBars so the 'No file selected' message is shown
    final prevSuppress = SettingsView.suppressSnackBarsInTests;
    SettingsView.suppressSnackBarsInTests = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView()),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    // Call importViaWebForTest where pickBackupOverride is null; wrapper
    // will call pickBackupFileViaBrowser which returns null in tests,
    // exercising the 'No file selected' branch.
    await tester.runAsync(() async {
      // Call the private wrapper via dynamic state
      await (state as dynamic).importViaWebForTest(
        tester.element(find.byType(SettingsView)),
        repo,
        persistence,
      );
    });

    await tester.pumpAndSettle();
    expect(find.textContaining('No file selected'), findsWidgets);

    // restore flag
    SettingsView.suppressSnackBarsInTests = prevSuppress;
  });

  testWidgets('importFromDocumentsForTest with empty list shows no backups', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    // Temporarily allow SnackBars so the 'No backup files found' message is shown
    final prevSuppress = SettingsView.suppressSnackBarsInTests;
    SettingsView.suppressSnackBarsInTests = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async => [])),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).importFromDocumentsForTest(
        tester.element(find.byType(SettingsView)),
        repo,
        persistence,
      );
    });

    await tester.pumpAndSettle();

    expect(find.textContaining('No backup files found'), findsWidgets);

    // restore flag
    SettingsView.suppressSnackBarsInTests = prevSuppress;
  });

  testWidgets('importFromDocumentsChosenForTest dry-run failure path sets message', (tester) async {
    // Persistence that fails dryRun
    final persistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid format');
      return FakeImportResult(success: false, message: 'failed');
    });

    final repo = MatchRepository(persistence: persistence);

    // Provide a chosen file-like object with a .path field
    final chosen = _FakeFile('/tmp/fake-backup.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(readFileBytesOverride: (String p) async => Uint8List.fromList([1,2,3]))),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).importFromDocumentsChosenForTest(
        tester.element(find.byType(SettingsView)),
        repo,
        persistence,
        chosen,
      );
    });

    await tester.pumpAndSettle();

    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('importFromDocumentsConfirmedForTest success path sets message', (tester) async {
    final persistence = FakePersistence(); // default returns dryRun success and full success
    final repo = MatchRepository(persistence: persistence);

    final chosen = _FakeFile('/tmp/fake-good.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(readFileBytesOverride: (String p) async => Uint8List.fromList([1,2,3]))),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).importFromDocumentsConfirmedForTest(
        tester.element(find.byType(SettingsView)),
        repo,
        persistence,
        chosen,
      );
    });

    await tester.pumpAndSettle();

    expect(find.textContaining('Import successful'), findsWidgets);
  });
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}
