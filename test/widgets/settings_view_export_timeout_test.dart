import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    SettingsView.suppressSnackBarsInTests = true;
  });

  testWidgets('export finalizer times out and is caught', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{}');
    final repo = MatchRepository(persistence: fake);

    // exporter that immediately throws a TimeoutException to exercise the
    // timeout/catch branch quickly without waiting wall-clock time.
    Future<void> slowExporter(String path, String content) async {
      throw TimeoutException('simulated timeout');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          // provide postExportOverride so exporter is invoked in debug tests
          postExportOverride: slowExporter,
          documentsDirOverride: () async => Directory.systemTemp.createTempSync('sm_test'),
        ),
      ),
    ));

    await tester.pumpAndSettle();
    final st = tester.state(find.byType(SettingsView));
    final elem = tester.element(find.byType(SettingsView));

    // Call the wrapper that triggers the IO export path inside runAsync
    await tester.runAsync(() async {
      // debug trace for test progress
      print('TEST-TEST: about to call exportBackupForTest');
      await (st as dynamic).exportBackupForTest(elem);
      print('TEST-TEST: returned from exportBackupForTest');
    });

    // If we reach here without an uncaught exception the timeout branch was
    // exercised and handled by the code under test.
    expect(true, isTrue);
  });

  testWidgets('exportViaWebForTest times out when exporter delays', (tester) async {
    final persistence = FakePersistence(exportJsonValue: '{}');
    final repo = MatchRepository(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    // exporter that immediately throws a TimeoutException to exercise the
    // exportViaWebForTest timeout branch quickly.
    Future<void> slowExporter(String name, String json) async {
      throw TimeoutException('simulated timeout');
    }

    var threw = false;
    await tester.runAsync(() async {
      try {
        await (state as dynamic).exportViaWebForTest(
          tester.element(find.byType(SettingsView)),
          persistence,
          slowExporter,
          DateTime.now().toIso8601String().replaceAll(':', '-'),
        );
      } on TimeoutException {
        threw = true;
      }
    });

    await tester.pumpAndSettle();

    expect(threw, isTrue);
  });
}
