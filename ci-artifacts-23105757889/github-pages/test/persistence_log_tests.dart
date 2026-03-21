import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/services/persistence_service.dart';

void main() {
  setUp(() async {
    // Ensure clean in-memory prefs for each test
    SharedPreferences.setMockInitialValues({});
  });

  test('appendLog appends entries and persists them', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Initially empty
    var loaded = await svc.loadList('stagesLog');
    expect(loaded, isEmpty);

    // Append one entry
    final entry1 = {'timestampUtc': 't1', 'type': 'create', 'channel': 'test', 'data': {'stage': 1}};
    await svc.appendLog('stagesLog', entry1);

    loaded = await svc.loadList('stagesLog');
    expect(loaded.length, 1);
    expect(loaded.first['type'], 'create');
    expect(loaded.first['data']['stage'], 1);

    // Append another entry
    final entry2 = {'timestampUtc': 't2', 'type': 'update', 'channel': 'test', 'original': {'stage': 1}, 'updated': {'stage': 1, 'scoringShoots': 6}};
    await svc.appendLog('stagesLog', entry2);

    loaded = await svc.loadList('stagesLog');
    expect(loaded.length, 2);
    expect(loaded[1]['type'], 'update');
    expect(loaded[1]['updated']['scoringShoots'], 6);
  });

  test('importBackupFromBytes computes audit diffs and appends logs', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Seed existing data: one stage (stage 1), one shooter (Alice), one result (stage1-Alice)
    await prefs.setString('stages', jsonEncode([{'stage': 1, 'scoringShoots': 5}]));
    await prefs.setString('shooters', jsonEncode([{'name': 'Alice'}]));
    await prefs.setString('stageResults', jsonEncode([{'stage': 1, 'shooter': 'Alice', 'time': 10.0}]));

    // Build incoming backup: stage 1 updated, stage 2 created, no shooters, no results
    final incoming = {
      'metadata': {'schemaVersion': 5},
      'stages': [
        {'stage': 1, 'scoringShoots': 6},
        {'stage': 2, 'scoringShoots': 5}
      ],
      'shooters': [],
      'stageResults': []
    };

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(incoming)));

    final res = await svc.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: false);
    expect(res.success, isTrue);

    final stagesLog = await svc.loadList('stagesLog');
    final shootersLog = await svc.loadList('shootersLog');
    final resultsLog = await svc.loadList('stageResultsLog');

    // Expect an update for stage 1 and a create for stage 2
    expect(stagesLog, isNotEmpty);
    expect(stagesLog.any((e) => e['type'] == 'update'), isTrue);
    expect(stagesLog.any((e) => e['type'] == 'create' && (e['data']?['stage'] == 2)), isTrue);

    // Shooter 'Alice' should have been deleted
    expect(shootersLog.any((e) => e['type'] == 'delete' && e['data']?['name'] == 'Alice'), isTrue);

    // Stage result for Alice should have been deleted
    expect(resultsLog.any((e) => e['type'] == 'delete' && e['data']?['shooter'] == 'Alice'), isTrue);
  });
}
