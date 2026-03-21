import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/team_game_viewmodel.dart';
import 'package:simple_match/models/team_game.dart';

import '../widgets/test_helpers/fake_repo_and_persistence.dart';

void main() {
  group('TeamGameViewModel', () {
    late FakePersistence fake;
    late MatchRepository repo;
    late TeamGameViewModel vm;

    setUp(() async {
      fake = FakePersistence();
      repo = MatchRepository(persistence: fake);
      await repo.loadAll();
      vm = TeamGameViewModel(repo);
    });

    test('setMode and setTopCount update model', () async {
      vm.setMode('average');
      expect(vm.teamGame.mode, 'average');

      vm.setTopCount(3);
      expect(vm.teamGame.topCount, 3);
    });

    test('addTeam, renameTeam and removeTeam', () async {
      expect(vm.teamGame.teams, isEmpty);

      await vm.addTeam('Alpha');
      expect(vm.teamGame.teams.length, 1);
      final t = vm.teamGame.teams.first;
      expect(t.name, 'Alpha');

      await vm.renameTeam(t.id, 'Alpha Renamed');
      expect(vm.teamGame.teams.first.name, 'Alpha Renamed');

      await vm.removeTeam(t.id);
      expect(vm.teamGame.teams, isEmpty);
    });

    test('assignShooter and unassignShooter moves shooter between teams', () async {
      await vm.addTeam('Team1');
      await vm.addTeam('Team2');
      final t1 = vm.teamGame.teams[0];
      final t2 = vm.teamGame.teams[1];

      await vm.assignShooter(t1.id, 'Alice');
      expect(t1.members, contains('Alice'));
      expect(t2.members, isNot(contains('Alice')));

      // Assigning Alice to team2 should remove from team1
      await vm.assignShooter(t2.id, 'Alice');
      expect(t2.members, contains('Alice'));
      expect(t1.members, isNot(contains('Alice')));

      // Unassign removes from all teams
      await vm.unassignShooter('Alice');
      expect(t1.members, isNot(contains('Alice')));
      expect(t2.members, isNot(contains('Alice')));
    });

    test('reload reflects repository teamGame', () async {
      // create a team game and update repository directly
      final tg = TeamGame(mode: 'top', topCount: 2, teams: [Team(id: 'x', name: 'X')]);
      await repo.updateTeamGame(tg);

      // vm currently has old copy; reload should pick up repository value
      await vm.reload();
      expect(vm.teamGame.mode, 'top');
      expect(vm.teamGame.topCount, 2);
      expect(vm.teamGame.teams.length, 1);
      expect(vm.teamGame.teams.first.name, 'X');
    });

    test('computeTeamScore average and top behaviors', () {
      final team = Team(id: 't', name: 'T', members: ['A', 'B', 'C']);
      final totals = {'A': 100.0, 'B': 80.0, 'C': 60.0};

      final tg = TeamGame(mode: 'average');
      final avg = tg.computeTeamScore(team, totals);
      expect(avg, closeTo((100 + 80 + 60) / 3, 1e-9));

      final tg2 = TeamGame(mode: 'top', topCount: 2);
      final topSum = tg2.computeTeamScore(team, totals);
      // top 2 are 100 + 80
      expect(topSum, closeTo(180.0, 1e-9));

      // topCount <= 0 should sum all
      final tg3 = TeamGame(mode: 'top', topCount: 0);
      final allSum = tg3.computeTeamScore(team, totals);
      expect(allSum, closeTo(240.0, 1e-9));
    });
  });
}
