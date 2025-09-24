import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';

void main() {
  group('ShooterSetupViewModel', () {
    test('can instantiate', () {
      final vm = ShooterSetupViewModel(MatchRepository());
      expect(vm, isA<ShooterSetupViewModel>());
    });
    // TODO: Add tests for add/edit/remove shooter logic
  });
}
