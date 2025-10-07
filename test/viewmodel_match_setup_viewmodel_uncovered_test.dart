import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  @override
  Future<List<MatchStage>> loadStages() async => [
    MatchStage(stage: 1, scoringShoots: 10),
  ];
}

void main() {
  test('MatchSetupViewModel edge cases', () {
    final repo = MatchRepository(
      persistence: MockPersistenceService(),
      initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
      initialShooters: [],
    );
    final vm = MatchSetupViewModel(repo);
    // Try to add duplicate stage
    final result = vm.addStage(1, 10);
    expect(result, isNotNull);
    // Try to add invalid stage
    final result2 = vm.addStage(-1, 10);
    expect(result2, isNotNull);
    // Try to add invalid scoring shoots
    final result3 = vm.addStage(2, -5);
    expect(result3, isNotNull);
  });
}
