import '../repository/match_repository.dart';
import '../models/shooter.dart';

/// ViewModel for overall result page.
class OverallResultViewModel {
  final MatchRepository repository;
  OverallResultViewModel(this.repository);

  /// Returns a list of shooter results sorted by total points descending.
  List<OverallShooterResult> getOverallResults() {
    final shooters = repository.shooters;
    final stages = repository.stages;
    final results = repository.results;
    // Map: shooter name -> total points
    final Map<String, double> shooterPoints = {
      for (var s in shooters) s.name: 0.0,
    };

    for (final stage in stages) {
      // Get all results for this stage
      final stageResults = results
          .where((r) => r.stage == stage.stage)
          .toList();
      if (stageResults.isEmpty) continue;
      // Compute adjusted hit factor for each shooter
      final Map<String, double> adjHitFactors = {};
      for (final r in stageResults) {
        final shooter = shooters.firstWhere(
          (s) => s.name == r.shooter,
          orElse: () => Shooter(name: r.shooter),
        );
        final totalScore =
            r.a * 5 +
            r.c * 3 +
            r.d * 1 -
            r.misses * 10 -
            r.noShoots * 10 -
            r.procedureErrors * 10;
        final hitFactor = r.time > 0 ? totalScore / r.time : 0.0;
        final adjHitFactor = hitFactor * shooter.scaleFactor;
        adjHitFactors[r.shooter] = adjHitFactor;
      }
      // Find highest adjusted hit factor in this stage
      final maxAdjHitFactor = adjHitFactors.values.isNotEmpty
          ? adjHitFactors.values.reduce((a, b) => a > b ? a : b)
          : 0.0;
      if (maxAdjHitFactor == 0.0) continue;
      // Assign stage points
      for (final r in stageResults) {
        final adjHit = adjHitFactors[r.shooter] ?? 0.0;
        final stagePoint = (adjHit / maxAdjHitFactor) * stage.scoringShoots * 5;
        shooterPoints[r.shooter] = (shooterPoints[r.shooter] ?? 0) + stagePoint;
      }
    }
    // Build and sort results
    final resultsList = shooterPoints.entries
        .map((e) => OverallShooterResult(name: e.key, totalPoints: e.value))
        .toList();
    resultsList.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return resultsList;
  }

  /// Returns a map of shooter name -> total points for use by team scoring.
  Map<String, double> getOverallTotalsMap() {
    final list = getOverallResults();
    return {for (final r in list) r.name: r.totalPoints};
  }
}

class OverallShooterResult {
  final String name;
  final double totalPoints;
  OverallShooterResult({required this.name, required this.totalPoints});
}
