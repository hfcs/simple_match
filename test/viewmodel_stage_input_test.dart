import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';

void main() {
  group('StageInputViewModel', () {
    test('can instantiate', () {
      final vm = StageInputViewModel(MatchRepository());
      expect(vm, isA<StageInputViewModel>());
    });
    // TODO: Add tests for input, validation, and calculation logic
  });
}
