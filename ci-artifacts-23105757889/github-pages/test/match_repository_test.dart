import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  test('add/update/remove stages', () async {
    final repo = MatchRepository();
    expect(repo.stages.length, 0);
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    expect(repo.stages.length, 1);

    // update
    await repo.updateStage(MatchStage(stage: 1, scoringShoots: 7, createdAtUtc: repo.getStage(1)!.createdAtUtc));
    final s = repo.getStage(1);
    expect(s, isNotNull);
    expect(s!.scoringShoots, 7);

    // remove
    await repo.removeStage(1);
    expect(repo.getStage(1), isNull);
  });

  test('add/update/remove shooters', () async {
    final repo = MatchRepository();
    await repo.addShooter(Shooter(name: 'S1'));
    expect(repo.getShooter('S1'), isNotNull);

    await repo.updateShooter(Shooter(name: 'S1', scaleFactor: 1.5, createdAtUtc: repo.getShooter('S1')!.createdAtUtc));
    final sh = repo.getShooter('S1');
    expect(sh, isNotNull);
    expect(sh!.scaleFactor, 1.5);

    await repo.removeShooter('S1');
    expect(repo.getShooter('S1'), isNull);
  });

  test('add/update/remove results', () async {
    final repo = MatchRepository();
    await repo.addResult(StageResult(stage: 1, shooter: 'R1'));
    expect(repo.getResult(1, 'R1'), isNotNull);

    await repo.updateResult(StageResult(stage: 1, shooter: 'R1', time: 12.3, createdAtUtc: repo.getResult(1,'R1')!.createdAtUtc));
    final r = repo.getResult(1, 'R1');
    expect(r, isNotNull);
    expect(r!.time, 12.3);

    await repo.removeResult(1, 'R1');
    expect(repo.getResult(1, 'R1'), isNull);
  });
}
