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

  testWidgets('importFromDocumentsChosenForTest - confirm dialog cancel', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    final chosen = _FakeFile('/tmp/fake-cancel.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(readFileBytesOverride: (String p) async => Uint8List.fromList([1,2,3]))),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    // Start the importFromDocumentsChosenForTest and cancel the AlertDialog
    await tester.runAsync(() async {
      final future = (state as dynamic).importFromDocumentsChosenForTest(
        tester.element(find.byType(SettingsView)),
        repo,
        persistence,
        chosen,
      );

      // Give the dry-run a moment to complete and the dialog to appear
      await Future.delayed(const Duration(milliseconds: 50));
      Navigator.of(tester.element(find.byType(SettingsView))).pop(false);
      await future;
    });

    await tester.pumpAndSettle();

    // Because we cancelled, there should be no Import successful message
    expect(find.textContaining('Import successful'), findsNothing);
  });

  testWidgets('Import Backup UI - SimpleDialog selection canceled', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);

    final fakeChosen = _FakeFile('/tmp/fake-ui.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async => [fakeChosen], readFileBytesOverride: (String p) async => Uint8List.fromList([1,2,3]))),
      ),
    );

    await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.upload_file));
    await tester.pump();

    // Dismiss the SimpleDialog by popping null (cancel)
    Navigator.of(tester.element(find.byType(SettingsView))).pop(null);

    await tester.pumpAndSettle();

    // No import should have occurred
    expect(find.textContaining('Import successful'), findsNothing);
  });
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}
