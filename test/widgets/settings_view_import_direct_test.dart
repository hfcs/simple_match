import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  test('Direct import flow (dry-run -> import -> repo.loadAll) updates repository', () async {
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final file = File('${tmpDir.path}/sm_ui_backup_direct.json');
    await file.writeAsString(jsonEncode(backup));
    final bytes = await file.readAsBytes();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);

    // Dry-run
    final dry = await persistence.importBackupFromBytes(bytes, dryRun: true);
    expect(dry.success, isTrue);

    // Actual import
    final res = await persistence.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: true);
    expect(res.success, isTrue);

    // Reload repository and check data
    await repo.loadAll();
    expect(repo.getShooter('Eve')?.name, equals('Eve'));

    try { tmpDir.deleteSync(recursive: true); } catch (_) {}
  });
}
