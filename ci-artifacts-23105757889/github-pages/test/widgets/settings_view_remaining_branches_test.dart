import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _Chosen {
  final String path;
  _Chosen(this.path);
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

// Small test-only repo that throws from loadAll() to exercise reload-failure paths.
class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({super.persistence});
  @override
  Future<void> loadAll() async => throw Exception('reload fail');
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SettingsView.suppressSnackBarsInTests = true;
  });

  tearDown(() {
    SettingsView.suppressSnackBarsInTests = false;
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('importViaWeb no file selected branch', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => null)),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    // Should complete without throwing
    await state.importViaWebForTest(state.context, repo, persistence);
    expect(find.textContaining('Status:'), findsOneWidget);
  });

  testWidgets('importFromDocuments empty list branch', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async => [])),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;
    // Should complete and not throw when no backups are found
    await state.importFromDocumentsForTest(state.context, repo, persistence);
    expect(find.textContaining('Status:'), findsOneWidget);
  });

  testWidgets('importFromDocumentsConfirmedForTest success path', (tester) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 4}})));
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages':1,'shooters':1,'stageResults':1});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(readFileBytesOverride: (String p) async => bytes),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Use the 'chosen' shim to avoid dialog interaction
    final chosen = _Chosen('/tmp/ok.json');
    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, chosen);

    // After successful import the status text should reflect success
    await tester.pumpAndSettle();
    expect(find.textContaining('Import successful'), findsWidgets);
  });

  testWidgets('exportBackupForTest with saveExportOverride', (tester) async {
    final persistence = FakePersistence(exportJsonValue: jsonEncode({'ok':true}));
    final repo = MatchRepository(persistence: persistence);
    String? seenPath;
    String? seenContent;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: (String p, String c) async { seenPath = p; seenContent = c; })),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;
    await state.exportBackupForTest(state.context);
    await tester.pumpAndSettle();

    expect(seenPath, isNotNull);
    expect(seenContent, isNotNull);
    expect(find.textContaining('Exported via override'), findsWidgets);
  });

  testWidgets('exportViaWebForTest wrapper calls exporter', (tester) async {
    final persistence = FakePersistence(exportJsonValue: jsonEncode({'ok':true}));
    final repo = MatchRepository(persistence: persistence);
    String? exportedName;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView()),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;
    // Force web branch to exercise exportViaWeb path
    SettingsView.forceKIsWeb = true;
    await state.exportViaWebForTest(state.context, persistence, (String name, String content) async { exportedName = name; }, 'ts123');
    await tester.pumpAndSettle();

    expect(exportedName, isNotNull);
    expect(find.textContaining('Exported to'), findsWidgets);
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('Dry-run validation failure path (web pick)', (tester) async {
    final bytes = Uint8List.fromList([9, 9, 9]);
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid schema');
      return FakeImportResult(success: false, message: 'should not reach');
    });

    final repo = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'bad.json', 'autoConfirm': true}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Could show both a SnackBar and the Status: text — accept one or more matches.
    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('Import succeeds but repo.loadAll throws (web pick)', (tester) async {
    final bytes = Uint8List.fromList([7, 7, 7]);
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final throwingRepo = _ThrowingRepo(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: throwingRepo,
      child: MaterialApp(
        home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'ok.json', 'autoConfirm': true}),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Could show reload failure in a SnackBar or inline status text.
    expect(find.textContaining('reload failed'), findsWidgets);
  });

  testWidgets('IO documents-list path: import failed and catch(e) path', (tester) async {
    final bytes = Uint8List.fromList([8, 8, 8]);

    // First case: import returns success=false
    final fakePersistenceFail = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: false, message: 'broken content');
    });

    final repoFail = MatchRepository(persistence: fakePersistenceFail);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repoFail,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [ _FakeFile('/tmp/b.json') ],
          readFileBytesOverride: (p) async => bytes,
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Choose the file
    await tester.tap(find.text('b.json'));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.widgetWithText(TextButton, 'Restore'));
    await tester.pumpAndSettle();

    // Could show both a SnackBar and the Status: text — accept one or more matches.
    expect(find.textContaining('Import failed:'), findsWidgets);

    // Second case: readFileBytes throws leading to catch(e) branch
    final fakePersistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });
    final repo2 = MatchRepository(persistence: fakePersistence);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo2,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [ _FakeFile('/tmp/c.json') ],
          readFileBytesOverride: (p) async => throw Exception('io fail'),
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('c.json'));
    await tester.pumpAndSettle();

    // readFileBytesOverride throws, so no confirm dialog will appear — expect the catch(e) path
    expect(find.textContaining('Import error:'), findsWidgets);
  });
}
