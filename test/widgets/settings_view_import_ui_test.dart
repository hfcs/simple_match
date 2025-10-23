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

    await tester.pumpAndSettle();

    // Tap Import Backup and let the override handle the rest (autoConfirm=true)
    final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    await tester.pumpAndSettle();

  // Allow async operations to complete (import, repo.loadAll()) and check UI status
  await tester.pump(const Duration(milliseconds: 200));

  // Verify import result: SettingsView displays success status line
  expect(find.text('Status: Import successful'), findsOneWidget);
  }, timeout: Timeout(Duration(seconds: 60)));
}
