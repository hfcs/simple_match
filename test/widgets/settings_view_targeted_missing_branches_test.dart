import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

class _ThrowingLoadRepo extends MatchRepository {
  _ThrowingLoadRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('repo load failed (test)');
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('exportBackupForTest hits web-export branch and coverage block', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final persistence = FakePersistence(exportJsonValue: jsonEncode({'ok': true}));
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Force web branch inside _exportBackup
    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(), // no saveExportOverride -> will exercise web branch when forced
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call the web export helper directly with a test exporter to avoid
    // platform file IO differences in the VM test runtime. This exercises
    // the same code path as the forced web branch and the coverage block.
    await state.exportViaWebForTest(state.context, persistence, (String n, String c) async {
      // simple no-op exporter for tests
      print('TEST: dummy exporter called with name=$n contentLen=${c.length}');
    }, 'test-ts');
    await tester.pumpAndSettle();

    // Should display a SnackBar indicating a browser download style export
    expect(find.textContaining('Exported to browser download'), findsWidgets);
  });

  testWidgets('importFromDocumentsConfirmedForTest dry-run failure shows validation failed', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Persistence will return dry-run failure when dryRun==true
    final persistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'validation failed');
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 2}})));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            readFileBytesOverride: (String path) async => bytes,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    final chosen = _FakeFile('/tmp/simple_match_test_backup.json');

    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, chosen);
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('importFromDocumentsConfirmedForTest handles repo.loadAll throwing (reload failed)', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final persistence = FakePersistence();
    final repo = _ThrowingLoadRepo(persistence: persistence);

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 2}})));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            readFileBytesOverride: (String path) async => bytes,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    final chosen = _FakeFile('/tmp/simple_match_test_backup.json');

    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, chosen);
    await tester.pumpAndSettle();

    // The code shows a SnackBar when reload fails
    expect(find.textContaining('Import succeeded but failed to reload repository'), findsWidgets);
  });
}
