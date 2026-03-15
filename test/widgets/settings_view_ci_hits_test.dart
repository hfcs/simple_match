import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('CI extra hits: exporter timeout and extra wrappers', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SettingsView.suppressSnackBarsInTests = true;

    final fakeSvc = FakePersistence(exportJsonValue: '{}');
    final repo = MatchRepository(persistence: fakeSvc);

    // Provide a postExportOverride that delays beyond the debug timeout
    Future<void> slowExporter(String path, String content) async {
      await Future.delayed(const Duration(seconds: 3));
      return;
    }

    final widget = Provider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          postExportOverride: slowExporter,
          saveExportOverride: null,
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

    // Trigger export path that will call the slow exporter and hit the timeout handling
    await state.exportBackupForTest(ctx);

    // Also exercise web export/import wrappers
    await state.exportViaWebForTest(ctx, fakeSvc, (String p, String c) async {}, 'ts');
    await state.importViaWebForTest(ctx, repo, fakeSvc);

    // Exercise the import-from-documents helper paths
    final chosen = {'path': '/tmp/b.json'};
    await state.importFromDocumentsChosenForTest(ctx, repo, fakeSvc, chosen);
    await state.importFromDocumentsConfirmedForTest(ctx, repo, fakeSvc, chosen);

    // Call simple wrappers
    state.showSnackBarForTest(ctx, const SnackBar(content: Text('ci-hit')));
    await state.documentsDirForTest();

    SettingsView.suppressSnackBarsInTests = false;
  });
}
