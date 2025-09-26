import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  List<Shooter> shooters;
  List<MatchStage> stages;
  List<StageResult> results;
  MockPersistenceService({required this.shooters, required this.stages, required this.results});
  @override
  Future<List<Shooter>> loadShooters() async => shooters;
  @override
  Future<List<MatchStage>> loadStages() async => stages;
  @override
  Future<List<StageResult>> loadStageResults() async => results;
}

void main() {
  group('StageResultViewModel', () {
    test('getStageRanks returns correct ranking for each stage', () async {
      final shooters = [
        Shooter(name: 'Alice', scaleFactor: 1.0),
        Shooter(name: 'Bob', scaleFactor: 1.5),
      ];
      final stages = [
        MatchStage(stage: 1, scoringShoots: 10),
        MatchStage(stage: 2, scoringShoots: 8),
      ];
      final results = [
        StageResult(stage: 1, shooter: 'Alice', time: 10, a: 5, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
        StageResult(stage: 1, shooter: 'Bob', time: 8, a: 6, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
        StageResult(stage: 2, shooter: 'Alice', time: 9, a: 4, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
      ];
      final vm = StageResultViewModel(persistenceService: MockPersistenceService(
        shooters: shooters,
        stages: stages,
        results: results,
      ));
      await Future.delayed(const Duration(milliseconds: 10)); // let notifyListeners run
      final ranks = vm.getStageRanks();
      expect(ranks[1]!.length, 2);
      expect(ranks[1]![0].name, 'Bob'); // Bob has higher hit factor
      expect(ranks[1]![1].name, 'Alice');
      expect(ranks[2]!.length, 1);
      expect(ranks[2]![0].name, 'Alice');
      // Check adjusted hit factor
      final bobAdj = ranks[1]![0].adjustedHitFactor;
      final bobRaw = ranks[1]![0].hitFactor;
      expect(bobAdj, closeTo(bobRaw * 1.5, 0.0001));
    });
  });
}
