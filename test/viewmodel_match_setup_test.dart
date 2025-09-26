import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';

void main() {
  group('MatchSetupViewModel', () {
    test('can instantiate', () {
      final vm = MatchSetupViewModel(MatchRepository());
      expect(vm, isA<MatchSetupViewModel>());
    });
    test('addStage adds a stage and validates input', () {
      final repo = MatchRepository();
      final vm = MatchSetupViewModel(repo);
      // Valid add
      final err1 = vm.addStage(1, 10);
      expect(err1, isNull);
      expect(repo.stages.length, 1);
      expect(repo.stages.first.stage, 1);
      // Duplicate stage
      final err2 = vm.addStage(1, 8);
      expect(err2, contains('already exists'));
      // Out of range
      final err3 = vm.addStage(0, 10);
      expect(err3, contains('between 1 and 30'));
      final err4 = vm.addStage(2, 0);
      expect(err4, contains('between 1 and 32'));
    });

    test('editStage updates scoring shoots and validates input', () {
      final repo = MatchRepository();
      final vm = MatchSetupViewModel(repo);
      vm.addStage(1, 10);
      // Valid edit
      final err1 = vm.editStage(1, 8);
      expect(err1, isNull);
      expect(repo.stages.first.scoringShoots, 8);
      // Not found
      final err2 = vm.editStage(2, 8);
      expect(err2, contains('not found'));
      // Out of range
      final err3 = vm.editStage(1, 0);
      expect(err3, contains('between 1 and 32'));
    });

    test('removeStage removes a stage', () {
      final repo = MatchRepository();
      final vm = MatchSetupViewModel(repo);
      vm.addStage(1, 10);
      vm.addStage(2, 8);
      expect(repo.stages.length, 2);
      vm.removeStage(1);
      expect(repo.stages.length, 1);
      expect(repo.stages.first.stage, 2);
    });
  });
}
