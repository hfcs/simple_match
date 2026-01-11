
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/team_game.dart';

void main() {
  test('PersistenceService save/load teamGame', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = PersistenceService();

    final tg = TeamGame(mode: 'top', topCount: 2, teams: [Team(id: 't1', name: 'Alpha', members: ['A', 'B'])]);
    await svc.saveTeamGame(tg.toJson());
    final loaded = await svc.loadTeamGame();
    expect(loaded, isNotNull);
    final decoded = TeamGame.fromJson(Map<String, dynamic>.from(loaded!));
    expect(decoded.mode, equals('top'));
    expect(decoded.topCount, equals(2));
    expect(decoded.teams.length, equals(1));
    expect(decoded.teams.first.members, containsAll(['A', 'B']));
  });
}
