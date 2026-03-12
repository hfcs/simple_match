import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    SettingsView.suppressSnackBarsInTests = true;
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('export saveExportOverride throwing shows Export failed', (tester) async {
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);

    final throwingExporter = (String path, String content) async {
      throw Exception('save failed');
    };

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: throwingExporter)),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });

    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('import from documents with readFileBytesOverride throwing shows Import error', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    // Provide a fake file in documents listing
    final fakeChosen = _FakeFile('/tmp/fake.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [fakeChosen],
            readFileBytesOverride: (String p) async {
              throw Exception('read failed');
            },
          ),
        ),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    // Trigger the Import Backup button which calls the public _importBackup
    await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.upload_file));
    await tester.pumpAndSettle();

    // Select the file from the SimpleDialog so the import flow continues
    expect(find.text('fake.json'), findsOneWidget);
    await tester.tap(find.text('fake.json'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import error'), findsWidgets);
  });
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}
