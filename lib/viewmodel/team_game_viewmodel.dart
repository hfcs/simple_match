import 'package:flutter/foundation.dart';
// no external uuid dependency; use timestamp-based ids
import '../models/team_game.dart';
import '../repository/match_repository.dart';

class TeamGameViewModel extends ChangeNotifier {
  final MatchRepository repo;
  TeamGame _teamGame;
  String _makeId() => DateTime.now().microsecondsSinceEpoch.toString();

  TeamGameViewModel(this.repo) : _teamGame = repo.teamGame ?? TeamGame();

  TeamGame get teamGame => _teamGame;

  void setMode(String mode) {
    _teamGame.mode = mode;
    notifyListeners();
    save();
  }

  void setTopCount(int n) {
    _teamGame.topCount = n;
    notifyListeners();
    save();
  }

  Future<void> addTeam(String name) async {
    final t = Team(id: _makeId(), name: name);
    _teamGame.teams.add(t);
    notifyListeners();
    await save();
  }

  Future<void> removeTeam(String id) async {
    _teamGame.teams.removeWhere((t) => t.id == id);
    notifyListeners();
    await save();
  }

  Future<void> renameTeam(String id, String newName) async {
    final idx = _teamGame.teams.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final old = _teamGame.teams[idx];
    // Replace the team object so listeners relying on identity changes refresh.
    final replaced = Team(id: old.id, name: newName, members: List<String>.from(old.members));
    _teamGame.teams[idx] = replaced;
    notifyListeners();
    await save();
    // Also notify repository listeners in case other parts of the UI read from the
    // repository directly (ensure assigned shooters UI refreshes everywhere).
    try {
      repo.notifyListeners();
    } catch (_) {}
  }

  Future<void> assignShooter(String teamId, String shooterName) async {
    // remove from any other team
    for (final t in _teamGame.teams) {
      t.members.remove(shooterName);
    }
    final team = _teamGame.teams.firstWhere((t) => t.id == teamId);
    if (!team.members.contains(shooterName)) team.members.add(shooterName);
    notifyListeners();
    await save();
  }

  Future<void> unassignShooter(String shooterName) async {
    for (final t in _teamGame.teams) {
      t.members.remove(shooterName);
    }
    notifyListeners();
    await save();
  }

  Future<void> save() async {
    await repo.updateTeamGame(_teamGame);
  }

  Future<void> reload() async {
    final loaded = repo.teamGame;
    _teamGame = loaded ?? TeamGame();
    notifyListeners();
  }
}
