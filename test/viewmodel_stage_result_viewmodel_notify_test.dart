import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';

class _MockPersistenceService extends PersistenceService {
  @override
  Future<List<StageResult>> loadStageResults() async => [
    StageResult(stage: 1, shooter: 'A', time: 10, a: 5, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
  ];
  @override
  Future<List<Shooter>> loadShooters() async => [
    Shooter(name: 'A', scaleFactor: 1.0),
  ];
  @override
  Future<List<MatchStage>> loadStages() async => [
    MatchStage(stage: 1, scoringShoots: 10),
  ];
}

void main() {
  test('StageResultViewModel notifies listeners on load', () async {
    final service = _MockPersistenceService();
    final vm = StageResultViewModel(persistenceService: service);
    bool notified = false;
    vm.addListener(() {
      notified = true;
    });
    // Wait for async _load to complete
    await Future.delayed(const Duration(milliseconds: 10));
    expect(notified, isTrue);
    // Also check that results are loaded
    expect(vm.results.length, 1);
    expect(vm.shooters.length, 1);
    expect(vm.stages.length, 1);
  });
}
