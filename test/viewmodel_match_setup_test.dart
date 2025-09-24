import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';

void main() {
  group('MatchSetupViewModel', () {
    test('can instantiate', () {
      final vm = MatchSetupViewModel(MatchRepository());
      expect(vm, isA<MatchSetupViewModel>());
    });
    // TODO: Add tests for add/edit/remove stage logic
  });
}
