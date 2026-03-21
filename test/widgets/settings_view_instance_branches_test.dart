import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class FakePersistenceService extends PersistenceService {
  @override
  Future<String> exportBackupJson() async {
    return '{"stages":[],"shooters":[],"stageResults":[]}';
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

void main() {
  testWidgets('Exercise instance-level SettingsView branches', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SettingsView.suppressSnackBarsInTests = true;

    final fakeSvc = FakePersistenceService();

    final repo = MatchRepository(persistence: null);

    // Provide simple overrides to exercise branches without platform channels
    final widget = Provider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          saveExportOverride: (String path, String content) async {},
          pickBackupOverride: () async => {'bytes': Uint8List.fromList('{}'.codeUnits), 'name': 'b.json', 'autoConfirm': true},
          listBackupsOverride: () async => [ {'path': '/tmp/b.json'} ],
          readFileBytesOverride: (String path) async => Uint8List.fromList('{}'.codeUnits),
          documentsDirOverride: () async => {'path': '/tmp'},
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
    final chosen = {'path': '/tmp/b.json'};
    await state.importFromDocumentsChosenForTest(ctx, repo, fakeSvc, chosen);
    await state.importFromDocumentsConfirmedForTest(ctx, repo, fakeSvc, chosen);

    // Also call the simple test wrappers
    state.showSnackBarForTest(ctx, const SnackBar(content: Text('hi')));
    await state.documentsDirForTest();

    SettingsView.suppressSnackBarsInTests = false;
  });
}
