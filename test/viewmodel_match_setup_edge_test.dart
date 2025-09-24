import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';

void main() {
  group('MatchSetupViewModel edge cases', () {
    late MatchRepository repo;
    late MatchSetupViewModel vm;
    setUp(() {
      repo = MatchRepository();
      vm = MatchSetupViewModel(repo);
    });

    test('addStage with min and max valid values', () {
      expect(vm.addStage(1, 1), isNull);
      expect(vm.addStage(30, 32), isNull);
      expect(repo.stages.length, 2);
    });

    test('addStage with negative and over max values', () {
      expect(vm.addStage(-1, 10), isNotNull);
      expect(vm.addStage(31, 10), isNotNull);
      expect(vm.addStage(2, 0), isNotNull);
      expect(vm.addStage(2, 33), isNotNull);
      expect(repo.stages, isEmpty);
    });

    test('editStage for non-existent stage', () {
      expect(vm.editStage(99, 10), 'Stage not found.');
    });

    test('removeStage for non-existent stage does not throw', () {
      expect(() => vm.removeStage(99), returnsNormally);
    });

    test('addStage after removal allows reuse of stage number', () {
      vm.addStage(5, 10);
      vm.removeStage(5);
      expect(vm.addStage(5, 12), isNull);
      expect(repo.stages.length, 1);
      expect(repo.stages.first.scoringShoots, 12);
    });
  });
}
