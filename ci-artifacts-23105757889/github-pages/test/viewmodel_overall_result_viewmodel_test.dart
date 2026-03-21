import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  test('OverallResultViewModel computes totals correctly', () async {
    final repo = MatchRepository();
    // Two shooters, one stage
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    await repo.addShooter(Shooter(name: 'S1', scaleFactor: 1.0));
    await repo.addShooter(Shooter(name: 'S2', scaleFactor: 1.0));

    // Results: S1 slightly better
    await repo.addResult(StageResult(stage: 1, shooter: 'S1', time: 10.0, a: 5, c: 0, d: 0));
    await repo.addResult(StageResult(stage: 1, shooter: 'S2', time: 12.0, a: 5, c: 0, d: 0));

    final vm = OverallResultViewModel(repo);
    final res = vm.getOverallResults();
    expect(res.length, greaterThanOrEqualTo(2));
    // S1 should be ahead of S2
    expect(res.first.name, 'S1');
    final map = vm.getOverallTotalsMap();
    expect(map.containsKey('S1'), isTrue);
  });
}
