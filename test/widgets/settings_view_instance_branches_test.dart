import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';

class FakePersistenceService extends PersistenceService {
  @override
  Future<String> exportBackupJson() async {
    return '{"stages":[],"shooters":[],"stageResults":[]}';
  }

  @override
  Future<void> ensureSchemaUpToDate() async {
    // no-op in fake to avoid SharedPreferences calls in VM tests
    return;
  }

  @override
  Future<List<MatchStage>> loadStages() async {
    return <MatchStage>[];
  }

  @override
  Future<List<Shooter>> loadShooters() async {
    return <Shooter>[];
  }

  @override
  Future<List<StageResult>> loadStageResults() async {
    return <StageResult>[];
  }

  @override
  Future<Map<String, dynamic>?> loadTeamGame() async {
    return null;
  }

  @override
  Future<File> exportBackupToFile(String path) async {
    // Return a dummy File object pointing to temp path; tests won't read it.
    return File(path);
  }

  @override
  Future<ImportResult> importBackupFromBytes(Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
    final counts = {'stages': 0, 'shooters': 0, 'stageResults': 0};
    if (dryRun) return ImportResult(success: true, counts: counts);
    return ImportResult(success: true, counts: counts);
  }
}

// Simple helper to simulate a File-like object with a `path` property.
class _ChosenFile {
  final String path;
  _ChosenFile(this.path);
}

void main() {
  testWidgets('Exercise instance-level SettingsView branches', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SettingsView.suppressSnackBarsInTests = true;

    final fakeSvc = FakePersistenceService();

    // Inject the fake persistence so VM tests don't call platform plugins.
    final repo = MatchRepository(persistence: fakeSvc);

    // Provide simple overrides to exercise branches without platform channels

    final widget = ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          saveExportOverride: (String path, String content) async {},
          pickBackupOverride: () async => {'bytes': Uint8List.fromList('{}'.codeUnits), 'name': 'b.json', 'autoConfirm': true},
          listBackupsOverride: () async => [ _ChosenFile('/tmp/b.json') ],
          readFileBytesOverride: (String path) async => Uint8List.fromList('{}'.codeUnits),
          documentsDirOverride: () async => Directory.systemTemp,
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    final ctx = tester.element(find.byType(SettingsView));

    // Call test-visible instance wrappers to hit internal branches deterministically
    await state.exportViaWebForTest(ctx, fakeSvc, (String p, String c) async {}, 'ts');
    await state.exportBackupForTest(ctx);

    // Simulate chosen file object for import-from-documents chosen-for-test
    final chosen = _ChosenFile('/tmp/b.json');
    // Start the import that shows a confirmation dialog, then accept it
    final importFuture = state.importFromDocumentsChosenForTest(ctx, repo, fakeSvc, chosen);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    await importFuture;

    // Also exercise the confirmed import path (no dialog)
    await state.importFromDocumentsConfirmedForTest(ctx, repo, fakeSvc, chosen);

    // Also call the simple test wrappers
    state.showSnackBarForTest(ctx, const SnackBar(content: Text('hi')));
    await state.documentsDirForTest();

    SettingsView.suppressSnackBarsInTests = false;
  });
}
