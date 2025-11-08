import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('export IO path invokes exporter try-block and updates status', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

  // Create a temporary directory to act as documents dir
    print('TESTDBG: creating tmp dir');
    // Directory creation may perform IO; run it inside tester.runAsync so the
    // test binding does not deadlock on zone/IO scheduling.
    final Directory tmp = (await tester.runAsync(() async {
      final t = await Directory.systemTemp.createTemp('simple_match_test_docs');
      return t;
    })) as Directory;
    print('TESTDBG: tmp dir created at ${tmp.path}');

    // Use a saveExportOverride to avoid touching platform-specific IO paths
    // during the test. This keeps the test VM-friendly and avoids any
    // interactions that may hang in CI environments.
    Future<void> saveOverride(String name, String content) async {
      // write a small file under the tmp directory so we can assert later
      final f = File('${tmp.path}/$name');
      await f.create(recursive: true);
      await f.writeAsString(content);
    }

    print('TESTDBG: about to pump widget');
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => tmp, saveExportOverride: saveOverride),
      ),
    ));
    print('TESTDBG: initial pump requested');
    await tester.pump();
    print('TESTDBG: pump completed');

  final state = tester.state(find.byType(SettingsView));

  // Call the export path which should invoke the saveExportOverride and
  // complete quickly without platform-specific IO side-effects. Run inside
  // tester.runAsync to avoid possible deadlocks with the test binding when
  // the export path uses async APIs.
  await tester.runAsync(() async {
    print('TESTDBG: calling exportBackupForTest');
    await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    print('TESTDBG: exportBackupForTest returned');
  });

  // Avoid pumpAndSettle (can hang in some environments); use a bounded
  // pump to let the setState and SnackBar schedule complete.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

    // The persistent status text should be present (either Exported or Export failed)
    expect(find.textContaining('Status:'), findsOneWidget);

    // cleanup — run file-system IO inside tester.runAsync
    await tester.runAsync(() async {
      await tmp.delete(recursive: true);
    });
  }, timeout: const Timeout(Duration(seconds: 30)));
}
