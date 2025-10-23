import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Web pickBackupOverride autoConfirm import succeeds', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          pickBackupOverride: () async => {'bytes': Uint8List.fromList([1,2,3]), 'name': 'test.json', 'autoConfirm': true},
        ),
      ),
    ));

    // Tap Import; the pickBackupOverride will be used and autoConfirm will skip dialog
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Expect success status or SnackBar
    expect(find.textContaining('Import successful'), findsWidgets);
  });
}
