import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFileObj {
  final String path;
  _FakeFileObj(this.path);
}

void main() {
  testWidgets('importFromDocumentsChosenForTest (non-confirmed): dry-run failure shows validation message', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'validation failed');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: (p) async => Uint8List.fromList([1,2,3])),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    final chosen = _FakeFileObj('/tmp/dummy.json');

    // Call the non-confirmed chosen helper which should hit the dry-run failure branch
    await (state as dynamic).importFromDocumentsChosenForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });
}
