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
    await tester.pumpAndSettle();

    // Ensure main menu is visible
    expect(find.text('Mini IPSC Match'), findsOneWidget);

    // Tap the Team Game Setup menu card
    final menuFinder = find.widgetWithText(ListTile, 'Team Game Setup');
    expect(menuFinder, findsOneWidget);
    await tester.tap(menuFinder);
    await tester.pumpAndSettle();

    // Should navigate to Team Game Setup view
    expect(find.text('Team Game Setup'), findsWidgets);

    // Pop back to main menu by tapping the AppBar back icon
    final backIcon = find.byIcon(Icons.arrow_back);
    expect(backIcon, findsOneWidget);
    await tester.tap(backIcon);
    await tester.pumpAndSettle();

    // Back on main menu
    expect(find.text('Mini IPSC Match'), findsOneWidget);
  });
}
