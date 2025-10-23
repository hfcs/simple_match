import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  test('Direct import flow (dry-run -> import) with FakePersistence', () async {
    // Use in-memory bytes so this test can run on web as well as native
    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Eve', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = utf8.encode(jsonEncode(backup));

    final persistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: true, message: 'ok', counts: {});
      return FakeImportResult(success: true, message: 'imported', counts: {});
    });

    // Dry-run
    final dry = await persistence.importBackupFromBytes(bytes as dynamic, dryRun: true);
    expect(dry.success, isTrue);

    // Actual import
    final res = await persistence.importBackupFromBytes(bytes as dynamic, dryRun: false, backupBeforeRestore: true);
    expect(res.success, isTrue);
  });
}
