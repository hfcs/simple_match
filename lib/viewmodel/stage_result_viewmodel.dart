import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/stage_result.dart';
import '../models/shooter.dart';
import '../models/match_stage.dart';
import '../repository/match_repository.dart';
import '../services/persistence_service.dart';

/// ViewModel for Stage Result page.
class StageResultViewModel extends ChangeNotifier {
  final MatchRepository repository;
  List<StageResult> _results = [];
  List<Shooter> _shooters = [];
  List<MatchStage> _stages = [];
  late final VoidCallback _repoListener;

  /// Backwards-compatible constructor:
  /// - `repository` can be passed directly (preferred)
  /// - or `persistenceService` can be passed (older tests) and a
  ///   `MatchRepository` will be constructed from it.
    StageResultViewModel({MatchRepository? repo, PersistenceService? persistenceService})
      : repository = repo ?? MatchRepository(persistence: persistenceService) {
    _repoListener = () {
      _load();
      notifyListeners();
    };
    this.repository.addListener(_repoListener);
    // If a PersistenceService was provided (tests), load directly from it
    // to avoid triggering production migration behavior (which calls
    // SharedPreferences.getInstance). Otherwise, let the repository load.
    if (persistenceService != null) {
      try {
        persistenceService.loadStages().then((s) {
          _stages = List<MatchStage>.from(s);
          notifyListeners();
        });
        persistenceService.loadShooters().then((s) {
          _shooters = List<Shooter>.from(s);
          notifyListeners();
        });
        persistenceService.loadStageResults().then((r) {
          _results = List<StageResult>.from(r);
          notifyListeners();
        });
      } catch (e) {
        if (kDebugMode) print('TESTDBG: StageResultViewModel - direct persistence load threw: $e');
      }
    } else {
      // Kick off an async load from repository (production path)
      try {
        repository.loadAll().then((_) {
          _load();
          notifyListeners();
        });
      } catch (_) {
        if (kDebugMode) print('TESTDBG: StageResultViewModel - repository.loadAll() threw');
      }
    }
    _load();
  }

  Future<void> _load() async {
    _results = List<StageResult>.from(repository.results);
    _shooters = List<Shooter>.from(repository.shooters);
    _stages = List<MatchStage>.from(repository.stages);
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
      final updated = _results[resultIndex].copyWith(status: newStatus);
      // Delegate to repository which sets updatedAt and persists
      await repository.updateResult(updated);
      // Reload local cache from repository
      _load();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      repository.removeListener(_repoListener);
    } catch (_) {}
    super.dispose();
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
