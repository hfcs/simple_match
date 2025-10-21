import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

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

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
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

    // After import completes, repo should contain the imported shooter
    await repo.loadAll();
    expect(repo.getShooter('Eve')?.name, equals('Eve'));

    // No filesystem cleanup needed since we used in-memory bytes
  });
}
