import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';

class TestPersistence {}

void main() {
  group('MatchSetupViewModel', () {
    late MatchRepository repo;
    late MatchSetupViewModel vm;
    setUp(() {
      repo = MatchRepository();
      vm = MatchSetupViewModel(repo);
    });

    test('addStage adds valid stage', () {
      final result = vm.addStage(2, 10);
      expect(result, isNull);
      expect(repo.stages.length, 1);
      expect(repo.stages.first.stage, 2);
      expect(repo.stages.first.scoringShoots, 10);
    });

    test('addStage rejects duplicate stage', () {
      vm.addStage(2, 10);
      final result = vm.addStage(2, 12);
      expect(result, isNotNull);
      expect(repo.stages.length, 1);
    });

    test('addStage rejects out-of-range stage', () {
      final result = vm.addStage(0, 10);
      expect(result, isNotNull);
      expect(repo.stages, isEmpty);
    });

    test('addStage rejects out-of-range scoringShoots', () {
      final result = vm.addStage(2, 33);
      expect(result, isNotNull);
      expect(repo.stages, isEmpty);
    });

    test('removeStage removes stage', () {
      vm.addStage(2, 10);
      vm.removeStage(2);
      expect(repo.stages, isEmpty);
    });

    test('editStage updates stage', () {
      vm.addStage(2, 10);
      final result = vm.editStage(2, 12);
      expect(result, isNull);
      expect(repo.stages.first.scoringShoots, 12);
    });

    test('editStage rejects invalid scoringShoots', () {
      vm.addStage(2, 10);
      final result = vm.editStage(2, 0);
      expect(result, isNotNull);
      expect(repo.stages.first.scoringShoots, 10);
    });
  });
}
