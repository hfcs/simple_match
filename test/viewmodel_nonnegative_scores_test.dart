import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  group('Non-negative score and hit factor checks', () {
    test('StageInputViewModel clamps totalScore and hitFactor to >= 0', () {
      final repo = MatchRepository();
      repo.addShooter(Shooter(name: 'Neg', scaleFactor: 1.0));
      repo.addStage(MatchStage(stage: 1, scoringShoots: 5));

      final vm = StageInputViewModel(repo);
      vm.selectStage(1);
      vm.selectShooter('Neg');

      // Set values that would produce a negative raw score
      vm.time = 5.0;
      vm.a = 0;
      vm.c = 0;
      vm.d = 0;
      vm.misses = 3; // penalties = 30
      vm.noShoots = 0;
      vm.procErrors = 0;

      expect(vm.totalScore, greaterThanOrEqualTo(0));
      expect(vm.hitFactor, greaterThanOrEqualTo(0.0));
    });

    test('OverallResultViewModel produces non-negative total points', () {
      final repo = MatchRepository();
      repo.addShooter(Shooter(name: 'Good', scaleFactor: 1.0));
      repo.addShooter(Shooter(name: 'Bad', scaleFactor: 1.0));
      repo.addStage(MatchStage(stage: 1, scoringShoots: 5));

      // Good result: positive score
      repo.addResult(StageResult(
        stage: 1,
        shooter: 'Good',
        time: 5.0,
        a: 3,
        c: 2,
        d: 0,
        misses: 0,
        noShoots: 0,
        procedureErrors: 0,
      ));

      // Bad result: heavy penalties would make raw negative
      repo.addResult(StageResult(
        stage: 1,
        shooter: 'Bad',
        time: 5.0,
        a: 0,
        c: 0,
        d: 0,
        misses: 3,
        noShoots: 0,
        procedureErrors: 0,
      ));

      final vm = OverallResultViewModel(repo);
      final results = vm.getOverallResults();

      // All totalPoints must be >= 0
      for (final r in results) {
        expect(r.totalPoints, isNot(isNaN));
        expect(r.totalPoints, greaterThanOrEqualTo(0.0));
      }

      // Good should rank above Bad
      final good = results.firstWhere((e) => e.name == 'Good');
      final bad = results.firstWhere((e) => e.name == 'Bad');
      expect(good.totalPoints, greaterThanOrEqualTo(bad.totalPoints));
    });
  });
}
