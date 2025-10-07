import '../models/match_stage.dart';
import '../repository/match_repository.dart';

/// ViewModel for match setup page.
class MatchSetupViewModel {
  final MatchRepository repository;
  MatchSetupViewModel(this.repository);

  /// Adds a stage. Returns null on success, or error string on failure.
  String? addStage(int stage, int scoringShoots) {
    if (stage < 1 || stage > 30) return 'Stage must be between 1 and 30.';
    if (scoringShoots < 1 || scoringShoots > 32)
      return 'Scoring shoots must be between 1 and 32.';
    if (repository.stages.any((s) => s.stage == stage))
      return 'Stage already exists.';
    repository.addStage(MatchStage(stage: stage, scoringShoots: scoringShoots));
    return null;
  }

  /// Removes a stage by stage number.
  void removeStage(int stage) {
    repository.removeStage(stage);
  }

  /// Edits a stage's scoring shoots. Returns null on success, or error string on failure.
  String? editStage(int stage, int scoringShoots) {
    if (scoringShoots < 1 || scoringShoots > 32)
      return 'Scoring shoots must be between 1 and 32.';
    final orig = repository.getStage(stage);
    if (orig == null) return 'Stage not found.';
    repository.updateStage(
      MatchStage(stage: stage, scoringShoots: scoringShoots),
    );
    return null;
  }
}
