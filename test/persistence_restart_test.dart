import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  test('status and roRemark persist across simulated restart', () async {
    // Prepare in-memory prefs
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Create persistence service and a repository, add data and save
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);

    // Add a stage and shooter
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    await repo.addShooter(Shooter(name: 'Alice', scaleFactor: 1.0));

    // Add a result with DNF status and roRemark
    final result = StageResult(
      stage: 1,
      shooter: 'Alice',
      time: 0.0,
      a: 0,
      c: 0,
      d: 0,
      misses: 0,
      noShoots: 0,
      procedureErrors: 0,
      status: 'DNF',
      roRemark: 'Safety issue noted',
    );

    await repo.addResult(result);

    // Simulate app restart by creating new PersistenceService and MatchRepository
    final prefs2 = await SharedPreferences.getInstance();
    final persistence2 = PersistenceService(prefs: prefs2);
    final repo2 = MatchRepository(persistence: persistence2);

    await repo2.loadAll();

    final loaded = repo2.getResult(1, 'Alice');
    expect(loaded, isNotNull);
    expect(loaded!.status, equals('DNF'));
    expect(loaded.roRemark, equals('Safety issue noted'));
  });
}
