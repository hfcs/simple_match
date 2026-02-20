import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Import Backup (integration-like) using pickBackupOverride', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Suppress SnackBars in this test to avoid timer/animation async work
    // preventing clean test shutdown.
    SettingsView.suppressSnackBarsInTests = true;
    try {

    // Avoid calling SharedPreferences.getInstance() here; the test uses
    // `FakePersistence` and doesn't need real SharedPreferences.

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = utf8.encode(jsonEncode(backup));
    const filename = 'sm_integ_like_backup.json';

  // Use FakePersistence to avoid platform plugins and make test deterministic
  final persistence = FakePersistence();
  final repo = MatchRepository(persistence: persistence);
  await repo.loadAll();
  if (true) print('TESTDBG: repo.loadAll returned, repo persistence=${repo.persistence.runtimeType}');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => <String, dynamic>{
              'bytes': Uint8List.fromList(bytes),
              'name': filename,
              'autoConfirm': true,
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    if (true) print('TESTDBG: after initial pumps');

    // Tap Import Backup to trigger the overridden picker + import flow.
    final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    if (true) print('TESTDBG: tapped Import Backup');
    // Allow framework to process the import flow briefly (don't wait for SnackBar)
    await tester.pump(const Duration(milliseconds: 300));
    if (true) print('TESTDBG: after short pump');

  // After import completes the UI should show a success status (persistence is faked)
  await tester.pump(const Duration(milliseconds: 200));
  if (true) print('TESTDBG: before final expect');
  expect(find.text('Status: Import successful'), findsOneWidget);
  if (true) print('TESTDBG: expect passed');

    // No filesystem cleanup needed since we used in-memory bytes
    } finally {
      // Ensure we reset the test-only flag even if the test fails.
      SettingsView.suppressSnackBarsInTests = false;
    }
  }, timeout: const Timeout(Duration(seconds: 45)));
}
