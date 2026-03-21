import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  test('stages and shooters persist across simulated restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);

    await repo.addStage(MatchStage(stage: 2, scoringShoots: 5));
    await repo.addShooter(Shooter(name: 'Charlie', scaleFactor: 1.2));

    // Simulate restart
    final prefs2 = await SharedPreferences.getInstance();
    final persistence2 = PersistenceService(prefs: prefs2);
    final repo2 = MatchRepository(persistence: persistence2);

    await repo2.loadAll();

    final stage = repo2.getStage(2);
    final shooter = repo2.getShooter('Charlie');

    expect(stage, isNotNull);
    expect(stage!.scoringShoots, equals(5));
    expect(shooter, isNotNull);
    expect(shooter!.scaleFactor, closeTo(1.2, 1e-6));
  });
}
