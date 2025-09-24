import '../models/match_stage.dart';
import '../models/shooter.dart';
import '../models/stage_result.dart';

/// Repository for managing match data (stages, shooters, results).
class MatchRepository {
  final List<MatchStage> _stages = [];
  final List<Shooter> _shooters = [];
  final List<StageResult> _results = [];

  // Stages
  List<MatchStage> get stages => List.unmodifiable(_stages);
  void addStage(MatchStage stage) => _stages.add(stage);
  void removeStage(int stageNumber) => _stages.removeWhere((s) => s.stage == stageNumber);
  void updateStage(MatchStage updated) {
    final idx = _stages.indexWhere((s) => s.stage == updated.stage);
    if (idx != -1) _stages[idx] = updated;
  }

  // Shooters
  List<Shooter> get shooters => List.unmodifiable(_shooters);
  void addShooter(Shooter shooter) => _shooters.add(shooter);
  void removeShooter(String name) => _shooters.removeWhere((s) => s.name == name);
  void updateShooter(Shooter updated) {
    final idx = _shooters.indexWhere((s) => s.name == updated.name);
    if (idx != -1) _shooters[idx] = updated;
  }

  // Results
  List<StageResult> get results => List.unmodifiable(_results);
  void addResult(StageResult result) => _results.add(result);
  void removeResult(int stage, String shooter) => _results.removeWhere((r) => r.stage == stage && r.shooter == shooter);
  void updateResult(StageResult updated) {
    final idx = _results.indexWhere((r) => r.stage == updated.stage && r.shooter == updated.shooter);
    if (idx != -1) _results[idx] = updated;
  }

  // Getters for single items
  MatchStage? getStage(int stageNumber) {
    try {
      return _stages.firstWhere((s) => s.stage == stageNumber);
    } catch (_) {
      return null;
    }
  }
  Shooter? getShooter(String name) {
    try {
      return _shooters.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }
  StageResult? getResult(int stage, String shooter) {
    try {
      return _results.firstWhere((r) => r.stage == stage && r.shooter == shooter);
    } catch (_) {
      return null;
    }
  }
}
