// Removed duplicate import

import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Migration logic upgrades old schema version and preserves data', () async {
    // Simulate old schema version in SharedPreferences
    SharedPreferences.setMockInitialValues({
      'dataSchemaVersion': 1, // Simulate v1 (current, so migration is a no-op)
      'shooters': '[{"name":"Bob","scaleFactor":1.0}]',
      'stages': '[{"stage":2,"scoringShoots":8}]',
      'stageResults': '[{"stage":2,"shooter":"Bob","time":9.5,"a":4,"c":2,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]',
    });
    final persistence = PersistenceService();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();
    expect(repo.stages.length, 1);
    expect(repo.stages.first.stage, 2);
    expect(repo.shooters.length, 1);
    expect(repo.shooters.first.name, 'Bob');
    expect(repo.results.length, 1);
    expect(repo.results.first.shooter, 'Bob');
    // Now simulate a future migration by lowering the app's schema version (simulate downgrade)
    SharedPreferences.setMockInitialValues({
      'dataSchemaVersion': 99, // Simulate future version, should clear data
      'shooters': '[{"name":"Carol","scaleFactor":1.0}]',
    });
    final repo2 = MatchRepository(persistence: persistence);
    await repo2.loadAll();
    expect(repo2.stages, isEmpty);
    expect(repo2.shooters, isEmpty);
    expect(repo2.results, isEmpty);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Repository can persist and reload all data', () async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  final persistence = PersistenceService();
  final repo1 = MatchRepository(persistence: persistence);
  // Add data and save
  await repo1.addStage(MatchStage(stage: 1, scoringShoots: 10));
  await repo1.addShooter(Shooter(name: 'Alice', scaleFactor: 0.9));
  await repo1.addResult(StageResult(stage: 1, shooter: 'Alice', time: 12.3, a: 5, c: 3, d: 2, misses: 1, noShoots: 0, procedureErrors: 0));
  await repo1.saveAll();
  // Simulate app restart with a new repository instance
  final repo2 = MatchRepository(persistence: persistence);
  await repo2.loadAll();
  expect(repo2.stages.length, 1);
  expect(repo2.stages.first.stage, 1);
  expect(repo2.stages.first.scoringShoots, 10);
  expect(repo2.shooters.length, 1);
  expect(repo2.shooters.first.name, 'Alice');
  expect(repo2.shooters.first.scaleFactor, 0.9);
  expect(repo2.results.length, 1);
  final r = repo2.results.first;
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
