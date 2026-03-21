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
  });

  testWidgets('importFromDocumentsChosenForTest full-import failure shows Import failed', (tester) async {
    final persistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: false, message: 'import error');
    });

    final repo = MatchRepository(persistence: persistence);
    final chosen = _FakeFile('/tmp/fail.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(readFileBytesOverride: (String p) async => Uint8List.fromList([1,2,3]))),
      ),
    );

    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      final future = (state as dynamic).importFromDocumentsChosenForTest(
        tester.element(find.byType(SettingsView)),
        repo,
        persistence,
        chosen,
      );

      // Wait for the confirm dialog then confirm
      await Future.delayed(const Duration(milliseconds: 50));
      Navigator.of(tester.element(find.byType(SettingsView))).pop(true);
      await future;
    });

    await tester.pumpAndSettle();

    expect(find.textContaining('Import failed'), findsWidgets);
  });
}

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}
