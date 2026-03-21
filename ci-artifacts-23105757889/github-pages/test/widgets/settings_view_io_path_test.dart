import 'dart:io';
 

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exportBackup IO path writes file and updates status', (tester) async {
    // Prepare a temp directory and fake persistence
    final tmp = Directory.systemTemp.createTempSync('sm_test');
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    // Suppress snackbars to keep test deterministic
    SettingsView.suppressSnackBarsInTests = true;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => tmp),
      ),
    ));
    await tester.pumpAndSettle();

    final st = tester.state(find.byType(SettingsView));

    // Call the IO export path (no saveExportOverride) which should write a file
    await (st as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // Assert the UI status updated
    expect(find.textContaining('Exported to'), findsOneWidget);

    // Confirm a file was written into the temp directory
    final files = tmp.listSync().whereType<File>().toList();
    expect(files.isNotEmpty, isTrue);

    // Cleanup
    tmp.deleteSync(recursive: true);
    SettingsView.suppressSnackBarsInTests = false;
  }, timeout: const Timeout(Duration(seconds: 30)));
}
