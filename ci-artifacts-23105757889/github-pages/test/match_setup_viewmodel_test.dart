import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/models/match_stage.dart';

void main() {
  test('addStage validation and success', () async {
    final repo = MatchRepository();
    final vm = MatchSetupViewModel(repo);

    // invalid stage number
    expect(vm.addStage(0, 5), isNotNull);
    expect(vm.addStage(31, 5), isNotNull);

    // invalid scoring shoots
    expect(vm.addStage(1, 0), isNotNull);
    expect(vm.addStage(1, 33), isNotNull);

    // valid add
    final err = vm.addStage(2, 10);
    expect(err, isNull);
    // repository should contain the new stage
    expect(repo.stages.any((s) => s.stage == 2 && s.scoringShoots == 10), isTrue);

    // duplicate stage should return error
    expect(vm.addStage(2, 12), isNotNull);
  });

  test('editStage updates existing stage and validates', () async {
    final repo = MatchRepository(initialStages: [MatchStage(stage: 3, scoringShoots: 6)]);
    final vm = MatchSetupViewModel(repo);

    // editing non-existent stage
    expect(vm.editStage(99, 5), isNotNull);

    // invalid scoring shoots
    expect(vm.editStage(3, 0), isNotNull);

    // valid edit
    final err = vm.editStage(3, 8);
    expect(err, isNull);
    final updated = repo.getStage(3);
    expect(updated, isNotNull);
    expect(updated!.scoringShoots, 8);
  });
}
