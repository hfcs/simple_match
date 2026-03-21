import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

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

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('instance wrappers: exportViaWebForTest and importViaWebForTest', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // small backup bytes
    final backup = jsonEncode({'metadata': {'schemaVersion': 2}, 'stages': [], 'shooters': [], 'stageResults': []});
    final bytes = Uint8List.fromList(utf8.encode(backup));

    // Force web branches to run in VM tests
    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'web.json', 'autoConfirm': true},
            saveExportOverride: (String path, String content) async {
              // no-op exporter used in tests
            },
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Obtain the State object and call test-only wrappers directly
    final state = tester.state(find.byType(SettingsView)) as dynamic;

  // Call the web-export wrapper (provide a synthetic timestamp string)
  await state.exportViaWebForTest(state.context, persistence, (String p, String c) async {}, 'test-ts');

    // Call the web-import wrapper which will use the pickBackupOverride
    await state.importViaWebForTest(state.context, repo, persistence);

    // After importViaWebForTest completes the view will show SnackBars; ensure no exceptions
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsWidgets);
  });

  testWidgets('instance wrapper: importFromDocumentsConfirmedForTest', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final backup = jsonEncode({'metadata': {'schemaVersion': 2}, 'stages': [], 'shooters': [], 'stageResults': []});
    final bytes = Uint8List.fromList(utf8.encode(backup));

    // Provide a readFileBytesOverride which the widget will use when reading chosen.path
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [ _FakeFile('/tmp/simple_match_test_backup.json') ],
            readFileBytesOverride: (String path) async => bytes,
            documentsDirOverride: () async => Directory.systemTemp,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call importFromDocumentsConfirmedForTest with a fake chosen file and ensure it runs
    final chosen = _FakeFile('/tmp/simple_match_test_backup.json');
    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, chosen);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SnackBar), findsWidgets);
  });
}
