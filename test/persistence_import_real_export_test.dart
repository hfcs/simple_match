import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  test('import of a real exported JSON succeeds (dry-run and apply)', () async {
    // Build a realistic exported backup JSON map
    final backup = {
      'metadata': {
        'schemaVersion': 2,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'appVersion': 'test',
        'platform': 'web',
      },
      'stages': [
        {'stage': 1, 'scoringShoots': 10},
        {'stage': 2, 'scoringShoots': 8},
      ],
      'shooters': [
        {'name': 'Alice', 'scaleFactor': 0.9},
        {'name': 'Bob', 'scaleFactor': 1.0},
      ],
      'stageResults': [
        {
          'stage': 1,
          'shooter': 'Alice',
          'time': 12.5,
          'a': 5,
          'c': 3,
          'd': 2,
          'misses': 0,
          'noShoots': 0,
          'procedureErrors': 0,
          'status': 'Completed',
          'roRemark': ''
        },
      ],
    };

    final jsonStr = jsonEncode(backup);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    // Use in-memory SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Dry-run should succeed and return correct counts
    final dry = await svc.importBackupFromBytes(bytes, dryRun: true);
    expect(dry.success, isTrue);
    expect(dry.counts['stages'], equals(2));
    expect(dry.counts['shooters'], equals(2));
    expect(dry.counts['stageResults'], equals(1));

    // Now perform the actual import (no backupBeforeRestore to keep prefs simple)
    final res = await svc.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: false);
    expect(res.success, isTrue);

    // Verify data saved to SharedPreferences
    final stagesRaw = prefs.getString('stages');
    final shootersRaw = prefs.getString('shooters');
    final resultsRaw = prefs.getString('stageResults');
    expect(stagesRaw, isNotNull);
    expect(shootersRaw, isNotNull);
    expect(resultsRaw, isNotNull);

    final decodedStages = jsonDecode(stagesRaw!) as List<dynamic>;
    final decodedShooters = jsonDecode(shootersRaw!) as List<dynamic>;
    final decodedResults = jsonDecode(resultsRaw!) as List<dynamic>;
    expect(decodedStages.length, equals(2));
    expect(decodedShooters.length, equals(2));
    expect(decodedResults.length, equals(1));
    expect(decodedShooters[0]['name'], equals('Alice'));
  });
}
