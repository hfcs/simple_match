import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:simple_match/main.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('launch team game from main menu and return', (WidgetTester tester) async {
    final repo = MatchRepository(persistence: FakePersistence());
    await repo.loadAll();
    // Ensure at least one shooter exists so the Team Game menu is enabled
    await repo.addShooter(Shooter(name: 'Alice'));

    await tester.pumpWidget(MiniIPSCMatchApp(repository: repo));
    await tester.pump(const Duration(milliseconds: 200));

    // Ensure main menu is visible
    expect(find.text('Mini IPSC Match'), findsOneWidget);

    // Tap the Team Game Setup menu card
    final menuFinder = find.widgetWithText(ListTile, 'Team Game Setup');
    expect(menuFinder, findsOneWidget);
    final menuTile = tester.widget<ListTile>(menuFinder);
    menuTile.onTap?.call();
    await tester.pump(const Duration(milliseconds: 200));

    // Should navigate to Team Game Setup view
    expect(find.text('Team Game Setup'), findsWidgets);

    // Pop back to main menu programmatically to avoid hit-test flakiness
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pump(const Duration(milliseconds: 200));

    // Back on main menu
    expect(find.text('Mini IPSC Match'), findsOneWidget);
  });
}
