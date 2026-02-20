import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

/// Small fake file-like object used by tests to simulate a file listed in the
/// application documents directory. Only exposes a `path` property which the
/// production code reads when listing backup files.
class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
    testWidgets('Import flow: dismissing Select backup dialog returns early (cancel)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final persistence = FakePersistence();
      final repo = MatchRepository(persistence: persistence);
      await repo.loadAll();

      // Provide a single file so the SimpleDialog shows an option, but simulate
      // the user dismissing the dialog (tap outside) which returns null.
      await tester.pumpWidget(
        ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: MaterialApp(
            home: SettingsView(
              listBackupsOverride: () async => [ _FakeFile('/tmp/backup.json') ],
              readFileBytesOverride: (String p) async => Uint8List.fromList(utf8.encode('{}')),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open the import dialog
      await tester.tap(find.text('Import Backup'));
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog should be visible
      expect(find.text('Select backup to import'), findsOneWidget);

      // Tap outside the dialog to dismiss (barrierDismissible true by default)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 200));

      // The dialog was dismissed and no SnackBar should be shown by the code
      // path that handles a null choice (it simply returns early).
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('Import successful'), findsNothing);
    });

    testWidgets('Export flow: exporter throws shows Export failed SnackBar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final persistence = FakePersistence(exportJsonValue: '{}');
      final repo = MatchRepository(persistence: persistence);
      await repo.loadAll();

      // Provide an exporter override that throws to exercise the catch branch
      Future<void> throwingExporter(String path, String json) async {
        throw Exception('simulated exporter failure');
      }

      await tester.pumpWidget(
        ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: MaterialApp(home: SettingsView(saveExportOverride: throwingExporter)),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Export Backup'));
      await tester.pump(const Duration(milliseconds: 200));

  expect(find.byType(SnackBar), findsOneWidget);
  expect(find.textContaining('Export failed'), findsWidgets);
    });

  testWidgets('Export flow: pickBackupOverride returns null shows No file selected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => null)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should show a No file selected SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('No file selected'), findsOneWidget);
  });

  testWidgets('Export flow: dry-run fails shows validation failed SnackBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad backup');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'bad.json'})),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Backup validation failed'), findsOneWidget);
  });

  testWidgets('Import flow: repo.loadAll throws after successful import shows reload failed status', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 1, 'stageResults': 0});
      return FakeImportResult(success: true);
    });

    final throwRepo = _ThrowRepo(persistence);
    // initialize without throwing; subsequent loadAll calls will throw
    await throwRepo.initializeForTest();

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [{'name': 'X', 'scaleFactor': 1.0}],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: throwRepo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'ok.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump();

    // Trigger the import action (UI tap). The repository will throw on reloadAll(), which
    // should make the UI show a reload-failed status.
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import succeeded, reload failed'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Force web export/import paths are reachable via state wrappers', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{}', importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Force web mode to hit web-specific branches
    SettingsView.forceKIsWeb = true;

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: (String name, String json) async {}, pickBackupOverride: () async => {'bytes': bytes, 'name': 'web.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump();

    // Use the state's test-only wrappers to exercise web export/import deterministically.
    final state = tester.state(find.byType(SettingsView)) as dynamic;
    await state.exportViaWebForTest(
      tester.element(find.byType(SettingsView)),
      persistence,
      (String name, String json) async {},
      DateTime.now().toIso8601String(),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final repo2 = MatchRepository(persistence: persistence);
    await repo2.loadAll();
    await state.importViaWebForTest(tester.element(find.byType(SettingsView)), repo2, persistence);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import successful'), findsWidgets);

    // Reset the forced flag
    SettingsView.forceKIsWeb = false;
  });
}

/// Small helper repo that throws during loadAll() to exercise error path.
class _ThrowRepo extends MatchRepository {
  bool _shouldThrow = false;
  _ThrowRepo(persistence): super(persistence: persistence);

  /// Call this during test setup to initialize internals without throwing.
  Future<void> initializeForTest() async {
    // loadAll once to initialize internal state
    await super.loadAll();
    // subsequent loadAll() calls will throw to exercise the error path
    _shouldThrow = true;
  }

  @override
  Future<void> loadAll() async {
    if (_shouldThrow) throw Exception('loadAll exploded for test');
    return await super.loadAll();
  }
}

