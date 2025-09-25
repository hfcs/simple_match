// Removed duplicate import
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Repository can persist and reload all data', () async {
    final persistence = PersistenceService();
    final repo = MatchRepository(persistence: persistence);
    // Add data
    repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
  repo.addShooter(Shooter(name: 'Alice', scaleFactor: 0.9));
    repo.addResult(StageResult(stage: 1, shooter: 'Alice', time: 12.3, a: 5, c: 3, d: 2, misses: 1, noShoots: 0, procedureErrors: 0));
    await repo.saveAll();
    // Clear and reload
    repo.removeStage(1);
    repo.removeShooter('Alice');
    repo.removeResult(1, 'Alice');
    expect(repo.stages, isEmpty);
    expect(repo.shooters, isEmpty);
    expect(repo.results, isEmpty);
    await repo.loadAll();
    expect(repo.stages.length, 1);
    expect(repo.stages.first.stage, 1);
    expect(repo.stages.first.scoringShoots, 10);
    expect(repo.shooters.length, 1);
    expect(repo.shooters.first.name, 'Alice');
  expect(repo.shooters.first.scaleFactor, 0.9);
    expect(repo.results.length, 1);
    final r = repo.results.first;
    expect(r.stage, 1);
    expect(r.shooter, 'Alice');
    expect(r.time, 12.3);
    expect(r.a, 5);
    expect(r.c, 3);
    expect(r.d, 2);
    expect(r.misses, 1);
    expect(r.noShoots, 0);
    expect(r.procedureErrors, 0);
  });
}
