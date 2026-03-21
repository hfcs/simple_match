import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PersistenceService', () {
    test('can instantiate', () {
      final service = PersistenceService();
      expect(service, isA<PersistenceService>());
    });

    test('can save and load shooters', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PersistenceService();
      // Save shooters
      await service.saveList('shooters', [
        {'name': 'Alice', 'scaleFactor': 1.0},
        {'name': 'Bob', 'scaleFactor': 0.9},
      ]);
      final shooters = await service.loadShooters();
      expect(shooters.length, 2);
      expect(shooters[0].name, 'Alice');
      expect(shooters[1].scaleFactor, 0.9);
    });

    test('can save and load stages', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PersistenceService();
      await service.saveList('stages', [
        {'stage': 1, 'scoringShoots': 10},
        {'stage': 2, 'scoringShoots': 8},
      ]);
      final stages = await service.loadStages();
      expect(stages.length, 2);
      expect(stages[0].stage, 1);
      expect(stages[1].scoringShoots, 8);
    });

    test('can save and load stage results', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PersistenceService();
      await service.saveList('stageResults', [
        {
          'stage': 1,
          'shooter': 'Alice',
          'time': 12.3,
          'a': 5,
          'c': 3,
          'd': 2,
          'misses': 1,
          'noShoots': 0,
          'procedureErrors': 0,
        },
      ]);
      final results = await service.loadStageResults();
      expect(results.length, 1);
      expect(results[0].shooter, 'Alice');
      expect(results[0].time, 12.3);
      expect(results[0].a, 5);
    });
  });
}
