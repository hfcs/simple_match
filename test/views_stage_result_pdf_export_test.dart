import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:pdf/widgets.dart' as pw;

class MockPersistenceService extends PersistenceService {
  List<Shooter> shooters;
  List<MatchStage> stages;
  List<StageResult> results;
  MockPersistenceService({required this.shooters, required this.stages, required this.results});
  @override
  Future<List<Shooter>> loadShooters() async => shooters;
  @override
  Future<List<MatchStage>> loadStages() async => stages;
  @override
  Future<List<StageResult>> loadStageResults() async => results;
}

void main() {
  test('PDF export generates a document with all stages and shooters', () async {
    final shooters = [
      Shooter(name: 'Alice', scaleFactor: 1.0),
      Shooter(name: 'Bob', scaleFactor: 1.5),
    ];
    final stages = [
      MatchStage(stage: 1, scoringShoots: 10),
      MatchStage(stage: 2, scoringShoots: 8),
    ];
    final results = [
      StageResult(stage: 1, shooter: 'Alice', time: 10, a: 5, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
      StageResult(stage: 1, shooter: 'Bob', time: 8, a: 6, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
      StageResult(stage: 2, shooter: 'Alice', time: 9, a: 4, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
    ];
    final vm = StageResultViewModel(persistenceService: MockPersistenceService(
      shooters: shooters,
      stages: stages,
      results: results,
    ));
  // Build the PDF for all stages using the static method
  final pdf = await StageResultViewBodyState.buildAllStagesResultPdf(vm.getStageRanks());
  final bytes = await pdf.save();
  expect(bytes, isNotNull);
  // Check that the PDF bytes are not empty (should contain content for 2 stages)
  expect(bytes.length, greaterThan(300));
  });
}
