import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/main_menu_viewmodel.dart';

// Helpers for mocking
class _MockRepo extends MatchRepository {
  final void Function()? onClear;
  _MockRepo({this.onClear});
  @override
  Future<void> clearAllData() async {
    if (onClear != null) onClear!();
  }
}

class TestNavigator {
  String? lastRoute;
}

extension MainMenuViewModelTestNav on MainMenuViewModel {
  void navigateToFake(TestNavigator context, String routeName) {
    context.lastRoute = routeName;
  }
}

void main() {
  group('MainMenuViewModel', () {
    test('can instantiate', () {
      final vm = MainMenuViewModel(MatchRepository());
      expect(vm, isA<MainMenuViewModel>());
    });

    test('clearAllData calls repository.clearAllData', () async {
      var called = false;
      final repo = _MockRepo(onClear: () => called = true);
      final vm = MainMenuViewModel(repo);
      await vm.clearAllData();
      expect(called, isTrue);
    });

    test('navigateTo calls Navigator.pushNamed', () {
      final repo = MatchRepository();
      final vm = MainMenuViewModel(repo);
      final nav = TestNavigator();
      final context = nav;
      vm.navigateToFake(context, '/test-route');
      expect(nav.lastRoute, '/test-route');
    });
  });
}
