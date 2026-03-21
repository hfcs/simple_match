import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeChosen {
  final String path;
  _FakeChosen(this.path);
}

void main() {
  testWidgets('call state wrappers to exercise import/export branches', (tester) async {
    // Ensure snackbars display path is exercised
    final repo = MatchRepository(persistence: FakePersistence());

    // exporter no-op
    Future<void> exporter(String path, String content) async {}

    // list/read overrides
    Future<List<_FakeChosen>> listBackups() async => [ _FakeChosen('/tmp/fake.json') ];
    Future<Uint8List> readFileBytes(String path) async => Uint8List.fromList('{"fromFile":1}'.codeUnits);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          listBackupsOverride: () async => await listBackups(),
          readFileBytesOverride: (p) async => await readFileBytes(p),
          pickBackupOverride: () async => <String, dynamic>{
            'bytes': Uint8List.fromList('{"stages": [], "shooters": [], "stageResults": []}'.codeUnits),
            'name': 'demo.json',
            'autoConfirm': true,
          },
          saveExportOverride: (String p, String c) async {},
        ),
      ),
    ));

    await tester.pumpAndSettle();
    final st = tester.state(find.byType(SettingsView));
    final elem = tester.element(find.byType(SettingsView));

    // Call export via web wrapper
    await (st as dynamic).exportViaWebForTest(elem, repo.persistence ?? FakePersistence(), exporter, DateTime.now().toIso8601String());

    // Call full export wrapper (uses saveExportOverride)
    await (st as dynamic).exportBackupForTest(elem);

    // Call import via web wrapper (uses pickBackupOverride)
    await (st as dynamic).importViaWebForTest(elem, repo, repo.persistence ?? FakePersistence());

    // Call chosen import helper (dialog-free) using the first listed backup
    final listed = await (st as dynamic).widget.listBackupsOverride!();
    final first = listed.isNotEmpty ? listed.first : _FakeChosen('/tmp/fake.json');
    await (st as dynamic).importFromDocumentsConfirmedForTest(elem, repo, repo.persistence ?? FakePersistence(), first);

    // Call chosen/confirmed import helper directly with a fake chosen
    final chosen = _FakeChosen('/tmp/fake.json');
    await (st as dynamic).importFromDocumentsConfirmedForTest(elem, repo, repo.persistence ?? FakePersistence(), chosen);

    // Exercise the non-test-suppressed path: enable SnackBars and run confirmed import
    final prior = SettingsView.suppressSnackBarsInTests;
    SettingsView.suppressSnackBarsInTests = false;
    try {
      await (st as dynamic).importFromDocumentsConfirmedForTest(elem, repo, repo.persistence ?? FakePersistence(), chosen);
    } finally {
      SettingsView.suppressSnackBarsInTests = prior;
    }
  });
}
