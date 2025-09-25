import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  group('OverallResultViewModel', () {
    test('can instantiate', () {
      final vm = OverallResultViewModel(MatchRepository());
      expect(vm, isA<OverallResultViewModel>());
    });
    test('calculates and ranks overall results correctly', () {
      final repo = MatchRepository();
  repo.addShooter(Shooter(name: 'Alice', scaleFactor: 1.0));
  repo.addShooter(Shooter(name: 'Bob', scaleFactor: 0.9));
      repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
      repo.addStage(MatchStage(stage: 2, scoringShoots: 8));
      // Stage 1 results
      repo.addResult(StageResult(stage: 1, shooter: 'Alice', time: 10.0, a: 5, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0));
      repo.addResult(StageResult(stage: 1, shooter: 'Bob', time: 12.0, a: 4, c: 4, d: 2, misses: 0, noShoots: 0, procedureErrors: 0));
      // Stage 2 results
      repo.addResult(StageResult(stage: 2, shooter: 'Alice', time: 8.0, a: 4, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0));
      repo.addResult(StageResult(stage: 2, shooter: 'Bob', time: 9.0, a: 3, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0));

      final vm = OverallResultViewModel(repo);
      final results = vm.getOverallResults();
      // Should be sorted by total points descending
      expect(results.length, 2);
      expect(results[0].name, 'Alice');
      expect(results[1].name, 'Bob');
      // Check that total points are calculated and Bob's is less than Alice's
      expect(results[0].totalPoints, greaterThan(results[1].totalPoints));
    });
  });
}
