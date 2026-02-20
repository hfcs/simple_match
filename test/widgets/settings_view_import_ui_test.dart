import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Import Backup UI flow (select file, dry-run, restore) updates repository', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Avoid touching platform SharedPreferences in widget tests; use FakePersistence
    // and suppress SnackBars to prevent timers from interfering with the VM test run.
    SettingsView.suppressSnackBarsInTests = true;

    // Create a minimal valid backup JSON bytes in-memory
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

  // Use fake persistence (in-memory) for deterministic tests
  final persistence = FakePersistence();
  final repo = MatchRepository(persistence: persistence);
  // Enable importMode to keep persistence calls short/timeboxed during import flows
  repo.importMode = true;
  await repo.loadAll();

    // Provide pickBackupOverride so tests can simulate user picking a file.
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'sm_ui_backup.json', 'autoConfirm': true},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Tap Import Backup and let the override handle the rest (autoConfirm=true)
    final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    await tester.pump(const Duration(milliseconds: 200));
    // Wait for status line to update (poll briefly instead of a single pump)
    Future<void> waitForStatus(WidgetTester t, {int retries = 20}) async {
      for (var i = 0; i < retries; i++) {
        await t.pump(const Duration(milliseconds: 50));
        if (find.text('Status: Import successful').evaluate().isNotEmpty) return;
      }
    }

    await waitForStatus(tester);
    expect(find.text('Status: Import successful'), findsOneWidget);
    // Reset test-only flags
    SettingsView.suppressSnackBarsInTests = false;
  }, timeout: Timeout(Duration(seconds: 60)));
}
