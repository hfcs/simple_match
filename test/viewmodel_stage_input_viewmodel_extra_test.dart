import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  test('StageInputViewModel validation and submit/remove flows', () async {
    final repo = MatchRepository();
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 3));
    await repo.addShooter(Shooter(name: 'A', scaleFactor: 1.0));
    final vm = StageInputViewModel(repo);

    expect(vm.isValid, isFalse);
    vm.selectStage(1);
    vm.selectShooter('A');
    // fields default to zero -> invalid due to time and counts
    expect(vm.validationError, isNotNull);

    // set valid fields
    vm.a = 2; vm.c = 1; vm.d = 0; vm.misses = 0; vm.time = 10.0;
    expect(vm.totalScore, greaterThan(0));
    expect(vm.hitFactor, greaterThan(0));
    expect(vm.isValid, isTrue);

    await vm.submit();
    final r = repo.getResult(1, 'A');
    expect(r, isNotNull);

    // update status to DQ and submit; numeric fields should zero
    vm.setStatus('DQ');
    vm.setRoRemark('bad');
    await vm.submit();
    final r2 = repo.getResult(1, 'A');
    expect(r2!.time, equals(0.0));

    // remove
    await vm.remove();
    expect(repo.getResult(1, 'A'), isNull);
  });
}
