import '../models/match_stage.dart';
import '../models/shooter.dart';
import '../models/stage_result.dart';

/// Repository for managing match data (stages, shooters, results).
class MatchRepository {
  // TODO: Implement data source and persistence
  List<MatchStage> stages = [];
  List<Shooter> shooters = [];
  List<StageResult> results = [];
}
