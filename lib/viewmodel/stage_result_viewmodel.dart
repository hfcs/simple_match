import 'package:flutter/material.dart';
import '../models/stage_result.dart';
import '../models/shooter.dart';
import '../models/match_stage.dart';
import '../services/persistence_service.dart';

/// ViewModel for Stage Result page.
class StageResultViewModel extends ChangeNotifier {
  final PersistenceService persistenceService;
  List<StageResult> _results = [];
  List<Shooter> _shooters = [];
  List<MatchStage> _stages = [];

  StageResultViewModel({required this.persistenceService}) {
    _load();
  }

  Future<void> _load() async {
    _results = await persistenceService.loadStageResults();
    _shooters = await persistenceService.loadShooters();
    _stages = await persistenceService.loadStages();
    notifyListeners();
  }

  List<StageResult> get results => _results;
  List<Shooter> get shooters => _shooters;
  List<MatchStage> get stages => _stages;

  /// Returns a map of stage number to ranked list of {name, hitFactor, adjusted hit factor}
  Map<int, List<StageResultRank>> getStageRanks() {
    final Map<int, List<StageResultRank>> stageRanks = {};
    for (final stage in _stages) {
      final stageResults = _results.where((r) => r.stage == stage.stage).toList();
      final List<StageResultRank> ranks = stageResults.map((r) {
        final shooter = _shooters.firstWhere(
          (s) => s.name == r.shooter,
          orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0),
        );
        return StageResultRank(
          name: r.shooter,
          hitFactor: r.hitFactor,
          adjustedHitFactor: r.adjustedHitFactor(shooter.scaleFactor),
        );
      }).toList();
      ranks.sort((a, b) => b.hitFactor.compareTo(a.hitFactor));
      stageRanks[stage.stage] = ranks;
    }
    return stageRanks;
  }
}

class StageResultRank {
  final String name;
  final double hitFactor;
  final double adjustedHitFactor;
  StageResultRank({required this.name, required this.hitFactor, required this.adjustedHitFactor});
}
