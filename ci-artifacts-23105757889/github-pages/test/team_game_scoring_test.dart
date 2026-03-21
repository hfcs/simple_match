import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/team_game.dart';

void main() {
  test('TeamGame computeTeamScore average mode', () {
    final team = Team(id: 't1', name: 'Alpha', members: ['A', 'B', 'C']);
    final tg = TeamGame(mode: 'average', topCount: 0, teams: [team]);
    final totals = {'A': 100.0, 'B': 80.0, 'C': 60.0};
    final score = tg.computeTeamScore(team, totals);
    expect(score, closeTo((100.0 + 80.0 + 60.0) / 3.0, 1e-9));
  });

  test('TeamGame computeTeamScore top mode sums top N', () {
    final team = Team(id: 't1', name: 'Bravo', members: ['A', 'B', 'C', 'D']);
    final tg = TeamGame(mode: 'top', topCount: 2, teams: [team]);
    final totals = {'A': 50.0, 'B': 40.0, 'C': 30.0, 'D': 20.0};
    final score = tg.computeTeamScore(team, totals);
    // top 2 are 50 + 40
    expect(score, closeTo(90.0, 1e-9));
  });

  test('TeamGame computeTeamScore top mode with topCount > members', () {
    final team = Team(id: 't1', name: 'Charlie', members: ['A', 'B']);
    final tg = TeamGame(mode: 'top', topCount: 5, teams: [team]);
    final totals = {'A': 10.0, 'B': 20.0};
    final score = tg.computeTeamScore(team, totals);
    // Should sum both members
    expect(score, closeTo(30.0, 1e-9));
  });
}
