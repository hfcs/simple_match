import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:simple_match/main.dart' as app;
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Export -> Import flow', (tester) async {
    // Arrange: prepare a temp documents directory and mock path_provider via
    // environment variable; simplest approach is to use the actual app documents dir
    final tmpDir = Directory.systemTemp.createTempSync('sm_export_import_integ_');

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);

  // Seed repository with one shooter
  await repo.addShooter(Shooter(name: 'IntegrationShooter', scaleFactor: 1.0));

    // Launch app with the test repository provider
    await tester.pumpWidget(
      Provider<MatchRepository>.value(
        value: repo,
        child: app.MiniIPSCMatchApp(repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Settings via the app's UI (tap the Settings route button)
    // Navigate programmatically to Settings for determinism
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold).first);
      Navigator.of(context).pushNamed('/settings');
    });
    await tester.pumpAndSettle();

    // Press Export
    final exportBtn = find.text('Export Backup');
    expect(exportBtn, findsOneWidget);
    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    // Verify that a backup file exists in app documents dir
    // (This is somewhat environment-dependent; we assert that persistence.exportBackupJson() returns non-empty)
    final json = await persistence.exportBackupJson();
    expect(json, isNotEmpty);

    // Create a backup file manually and then import it via the app
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${tmpDir.path}/sm_test_backup_$ts.json';
    final file = File(path);
    await file.writeAsString(json);

    // Now simulate the import path: call importBackupFromBytes directly for determinism
    final bytes = await file.readAsBytes();
    final res = await persistence.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: true);
    expect(res.success, isTrue);

    // Cleanup
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  });
}
