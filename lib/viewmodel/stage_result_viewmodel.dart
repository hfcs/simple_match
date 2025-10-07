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

  /// Returns a map of stage number to ranked list of StageResultFullRank (sorted by scaled hit factor)
  Map<int, List<StageResultFullRank>> getStageRanks() {
    final Map<int, List<StageResultFullRank>> stageRanks = {};
    for (final stage in _stages) {
      final stageResults = _results
          .where((r) => r.stage == stage.stage)
          .toList();
      final List<StageResultFullRank> ranks = stageResults.map((r) {
        final shooter = _shooters.firstWhere(
          (s) => s.name == r.shooter,
          orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0),
        );
        return StageResultFullRank(
          name: r.shooter,
          hitFactor: r.hitFactor,
          adjustedHitFactor: r.adjustedHitFactor(shooter.scaleFactor),
          time: r.time,
          a: r.a,
          c: r.c,
          d: r.d,
          misses: r.misses,
          noShoots: r.noShoots,
          procedureErrors: r.procedureErrors,
        );
      }).toList();

      // Calculate adjusted match points for this stage
      if (ranks.isNotEmpty) {
        final maxAdjHitFactor = ranks
            .map((r) => r.adjustedHitFactor)
            .reduce((a, b) => a > b ? a : b);
        for (final rank in ranks) {
          final adjustedMatchPoint = maxAdjHitFactor > 0
              ? (rank.adjustedHitFactor / maxAdjHitFactor) *
                    stage.scoringShoots *
                    5
              : 0.0;
          rank.adjustedMatchPoint = adjustedMatchPoint;
        }
      }

      // Sort by scaled (adjusted) hit factor descending
      ranks.sort((a, b) => b.adjustedHitFactor.compareTo(a.adjustedHitFactor));
      stageRanks[stage.stage] = ranks;
    }
    return stageRanks;
  }

  Future<void> updateStatus(int stage, String shooter, String newStatus) async {
    final resultIndex = _results.indexWhere(
      (r) => r.stage == stage && r.shooter == shooter,
    );
    if (resultIndex != -1) {
      _results[resultIndex] = _results[resultIndex].copyWith(status: newStatus);
      await persistenceService.saveList(
        'stageResults',
        _results.map((r) => r.toJson()).toList(),
      );
      notifyListeners();
    }
  }
}

class StageResultFullRank {
  final String name;
  final double hitFactor;
  final double adjustedHitFactor;
  final double time;
  final int a;
  final int c;
  final int d;
  final int misses;
  final int noShoots;
  final int procedureErrors;
  double adjustedMatchPoint;

  StageResultFullRank({
    required this.name,
    required this.hitFactor,
    required this.adjustedHitFactor,
    required this.time,
    required this.a,
    required this.c,
    required this.d,
    required this.misses,
    required this.noShoots,
    required this.procedureErrors,
    this.adjustedMatchPoint = 0.0,
  });
}
