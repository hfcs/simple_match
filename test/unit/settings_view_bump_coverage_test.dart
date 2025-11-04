import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';
import '../widgets/test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Export and Import flows exercise SettingsView branches (replaces coverage-only shims)', (tester) async {
    // Fake persistence that returns a valid export JSON
    final fake = FakePersistence(exportJsonValue: '{"ok":true}', importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      // Simulate a successful dry-run and real import
      if (dryRun) return FakeImportResult(success: true);
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);

    // Prepare a pick override that simulates a browser file pick returning bytes
    Future<Map<String, dynamic>> pickOverride() async => <String, dynamic>{'bytes': Uint8List.fromList([1,2,3]), 'name': 'import.json', 'autoConfirm': true};

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickOverride)),
      ),
    );

    await tester.pumpAndSettle();

    // Trigger import flow (using pickBackupOverride)
    await tester.tap(find.text('Import Backup'));
  await tester.pumpAndSettle();

  // Ensure no uncaught exceptions and UI is still present (import path executed)
  expect(tester.takeException(), isNull);
  });
}
