import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/main_menu_viewmodel.dart';

void main() {
  group('MainMenuViewModel', () {
    test('can instantiate', () {
      final vm = MainMenuViewModel(MatchRepository());
      expect(vm, isA<MainMenuViewModel>());
    });
    // TODO: Add tests for navigation and clear data logic
  });
}
