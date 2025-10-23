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

    await tester.pumpAndSettle();

    // Tap Import Backup to trigger the overridden picker + import flow.
    final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    // Allow framework to process the import flow
    await tester.pumpAndSettle(const Duration(seconds: 1));

  // After import completes the UI should show a success status (persistence is faked)
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.text('Status: Import successful'), findsOneWidget);

    // No filesystem cleanup needed since we used in-memory bytes
  });
}
