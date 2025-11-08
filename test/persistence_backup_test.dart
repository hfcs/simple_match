import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  group('Persistence backup/import MVP', () {
    late PersistenceService svc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      svc = PersistenceService();
      // Ensure schema up to date (will set version)
      await svc.ensureSchemaUpToDate();
    });

    test('export produces JSON with expected keys', () async {
      final jsonStr = await svc.exportBackupJson();
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed.containsKey('metadata'), isTrue);
      expect(parsed.containsKey('stages'), isTrue);
      expect(parsed.containsKey('shooters'), isTrue);
      expect(parsed.containsKey('stageResults'), isTrue);
    });

    test('import dry run validates and returns counts without persisting', () async {
      // Build a small backup map
      final map = {
        'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
        'stages': [ {'stage': 1, 'scoringShoots': 5} ],
        'shooters': [ {'name': 'Alice', 'scaleFactor': 1.0} ],
        'stageResults': [
          {'stage': 1, 'shooter': 'Alice', 'time': 10.0, 'a': 5, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0, 'status': 'Completed', 'roRemark': ''}
        ],
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));
      final res = await svc.importBackupFromBytes(bytes, dryRun: true);
      expect(res.success, isTrue);
      expect(res.counts['stages'], equals(1));
      expect(res.counts['shooters'], equals(1));
      expect(res.counts['stageResults'], equals(1));

      // After dry-run, prefs should remain empty for lists
      final stages = await svc.loadStages();
      final shooters = await svc.loadShooters();
      final results = await svc.loadStageResults();
      expect(stages, isEmpty);
      expect(shooters, isEmpty);
      expect(results, isEmpty);
    });

    test('import persists data and can be loaded after import', () async {
      final map = {
        'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
        'stages': [ {'stage': 2, 'scoringShoots': 6} ],
        'shooters': [ {'name': 'Bob', 'scaleFactor': 1.2} ],
        'stageResults': [
          {'stage': 2, 'shooter': 'Bob', 'time': 12.5, 'a': 4, 'c': 1, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0, 'status': 'Completed', 'roRemark': ''}
        ],
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));
      final res = await svc.importBackupFromBytes(bytes, dryRun: false);
      expect(res.success, isTrue);
      expect(res.counts['stages'], equals(1));

      final stages = await svc.loadStages();
      final shooters = await svc.loadShooters();
      final results = await svc.loadStageResults();
      expect(stages.length, equals(1));
      expect(shooters.length, equals(1));
      expect(results.length, equals(1));

      expect(stages.first.stage, equals(2));
      expect(shooters.first.name, equals('Bob'));
      expect(results.first.shooter, equals('Bob'));
    });

    test('import rejects invalid JSON', () async {
      final bytes = Uint8List.fromList(utf8.encode('not a json'));
      final res = await svc.importBackupFromBytes(bytes, dryRun: true);
      expect(res.success, isFalse);
    });

    test('import rejects missing keys', () async {
      final map = {'metadata': {}, 'stages': []}; // missing shooters and stageResults
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));
      final res = await svc.importBackupFromBytes(bytes, dryRun: true);
      expect(res.success, isFalse);
    });
  });
}
