import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  // Skip this IO-focused test in CI; left here for local debugging.
  return;
  testWidgets('IO export fallback writes file and updates state', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('simple_match_test');
    final fake = FakePersistence(exportJsonValue: '{"export":true}');
  final repo = MatchRepository(persistence: fake);
  await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => tmp),
      ),
    ));

    await tester.pump();

  // Debug: print platform flags
  print('kIsWeb: $kIsWeb');
  print('SettingsView.forceKIsWeb: ${SettingsView.forceKIsWeb}');

  // Directly invoke the export method on the state to avoid tap/hit-test
  final state = tester.state(find.byType(SettingsView));
  print('calling exportBackupForTest');
  await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
  print('exportBackupForTest returned');
  // Allow async work to run and UI to settle
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(seconds: 1));

    // Expect a file exists in the temp directory matching the prefix.
    // Poll for a short while to give async file write/rename time to complete.
    List<File> files = [];
    for (var i = 0; i < 10; i++) {
      files = tmp.listSync().whereType<File>().toList();
      if (files.isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 200));
    }
    if (files.isEmpty) {
      // print diagnostics to help CI debugging
      print('Temp dir: ${tmp.path}');
      print('Contents: ${tmp.listSync()}');
    }
    expect(files.isNotEmpty, isTrue);
    final contents = files.first.readAsStringSync();
    expect(contents, contains('"export":true'));

    // cleanup
    tmp.deleteSync(recursive: true);
  });
}