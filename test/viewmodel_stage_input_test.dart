import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';

void main() {
  group('StageInputViewModel', () {
    late MatchRepository repo;
    late StageInputViewModel vm;
    setUp(() {
      repo = MatchRepository();
  repo.addShooter(Shooter(name: 'Alice', scaleFactor: 0.9));
  repo.addShooter(Shooter(name: 'Bob', scaleFactor: 1.0));
  repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
  repo.addStage(MatchStage(stage: 2, scoringShoots: 8));
      vm = StageInputViewModel(repo);
    });

    test('initializes with default values', () {
      expect(vm.selectedStage, isNull);
      expect(vm.selectedShooter, isNull);
      expect(vm.time, 0.0);
      expect(vm.a, 0);
      expect(vm.c, 0);
      expect(vm.d, 0);
      expect(vm.misses, 0);
      expect(vm.noShoots, 0);
      expect(vm.procErrors, 0);
    });

    test('selectStage and selectShooter loads or resets values', () {
      vm.selectStage(1);
      vm.selectShooter('Alice');
      expect(vm.selectedStage, 1);
      expect(vm.selectedShooter, 'Alice');
      expect(vm.time, 0.0);
      expect(vm.a, 0);
      // Add a result, then select again
      vm.time = 5.5;
      vm.a = 5;
      vm.c = 3;
      vm.d = 2;
      vm.misses = 0;
      vm.noShoots = 0;
      vm.procErrors = 0;
      vm.submit();
      vm.selectStage(1);
      vm.selectShooter('Alice');
      expect(vm.time, 5.5);
      expect(vm.a, 5);
      expect(vm.c, 3);
      expect(vm.d, 2);
    });

    test('validation disables submit if sum != scoring shoots', () {
  vm.selectStage(1);
  vm.selectShooter('Alice');
  vm.a = 3;
  vm.c = 3;
  vm.d = 3;
  vm.misses = 2; // 3+3+3+2=11, not equal to 10
  vm.time = 1.0;
  expect(vm.isValid, false);
  expect(vm.validationError, contains('10'));
  vm.a = 5;
  vm.c = 3;
  vm.d = 2;
  vm.misses = 0; // 5+3+2+0=10
  vm.time = 1.0; // set to valid time
  expect(vm.isValid, true);
  expect(vm.validationError, isNull);
    });

    test('hit factor and adjusted hit factor calculation', () {
      vm.selectStage(1);
      vm.selectShooter('Alice');
      vm.time = 10.0;
      vm.a = 5;
      vm.c = 3;
      vm.d = 2;
      vm.misses = 0;
      vm.noShoots = 0;
      vm.procErrors = 0;
      final totalScore = 5*5 + 3*3 + 2*1;
      final hitFactor = totalScore / 10.0;
      final adjHitFactor = hitFactor * 0.9;
      expect(vm.totalScore, totalScore);
      expect(vm.hitFactor, closeTo(hitFactor, 0.001));
      expect(vm.adjustedHitFactor, closeTo(adjHitFactor, 0.001));
    });

    test('submit adds or updates result', () {
      vm.selectStage(1);
      vm.selectShooter('Alice');
      vm.time = 10.0;
      vm.a = 5;
      vm.c = 3;
      vm.d = 2;
      vm.misses = 0;
      vm.noShoots = 0;
      vm.procErrors = 0;
  expect(repo.results.length, 0);
      vm.submit();
  expect(repo.results.length, 1);
      // Update
      vm.a = 4;
      vm.submit();
  expect(repo.results.length, 1);
  expect(repo.results.first.a, 4);
    });

    test('remove deletes result', () {
      vm.selectStage(1);
      vm.selectShooter('Alice');
      vm.time = 10.0;
      vm.a = 5;
      vm.c = 3;
      vm.d = 2;
      vm.misses = 0;
      vm.noShoots = 0;
      vm.procErrors = 0;
      vm.submit();
  expect(repo.results.length, 1);
      vm.remove();
  expect(repo.results.length, 0);
    });
  });
}
