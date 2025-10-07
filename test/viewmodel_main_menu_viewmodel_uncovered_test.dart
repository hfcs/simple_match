import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_match/viewmodel/main_menu_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';

class MockNavigatorObserver extends NavigatorObserver {
  List<Route> pushedRoutes = [];
  @override
  void didPush(Route route, Route? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

class TestRepo extends MatchRepository {
  bool clearCalled = false;
  @override
  Future<void> clearAllData() async {
    clearCalled = true;
  }
}

void main() {
  test('MainMenuViewModel edge case', () {
    final repo = MatchRepository();
    final vm = MainMenuViewModel(repo);
    // Just ensure it can be instantiated and used
    expect(vm, isA<MainMenuViewModel>());
  });

  testWidgets('navigateTo pushes named route', (tester) async {
    final repo = MatchRepository();
    final vm = MainMenuViewModel(repo);
    final observer = MockNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        routes: {'/test': (context) => const Text('Test Route')},
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => vm.navigateTo(context, '/test'),
              child: const Text('Go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(find.text('Test Route'), findsOneWidget);
  });

  test('clearAllData calls repository.clearAllData', () async {
    final repo = TestRepo();
    final vm = MainMenuViewModel(repo);
    await vm.clearAllData();
    expect(repo.clearCalled, isTrue);
  });
}
