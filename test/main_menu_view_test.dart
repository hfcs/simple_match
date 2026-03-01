import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  testWidgets('MainMenu shows disabled items when empty and enables when data present', (tester) async {
    final repo = MatchRepository(initialStages: [], initialShooters: [], initialResults: []);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: const MainMenuView(),
        ),
      ),
    );

    // Allow animations and frames to settle before asserting
    await tester.pumpAndSettle();
    // Ensure the bottom item is visible (ListView builds lazily in tests)
    await tester.scrollUntilVisible(find.text('Clear All Data'), 200.0, scrollable: find.byType(Scrollable));
    await tester.pumpAndSettle();

    // Empty repo -> the Clear All Data tile should be present and disabled
    final clearFinder = find.widgetWithText(ListTile, 'Clear All Data');
    expect(clearFinder, findsOneWidget);
    final ListTile clearTile = tester.widget<ListTile>(clearFinder);
    expect(clearTile.enabled, isFalse);
    // Stage Input subtitle should mention add stage and shooter
    expect(find.textContaining('Add at least one stage'), findsOneWidget);

    // Add a stage and a shooter to enable Stage Input
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    await repo.addShooter(Shooter(name: 'T1'));
    // Rebuild UI
    await tester.pumpAndSettle();

    // Now the Clear All Data tile should be enabled and Stage Input visible
    final ListTile clearTileAfter = tester.widget<ListTile>(clearFinder);
    expect(clearTileAfter.enabled, isTrue);
    expect(find.text('Stage Input'), findsOneWidget);
  });
 

  testWidgets('Stage Input shows helper when no stages or shooters', (WidgetTester tester) async {
    final repo = MatchRepository(initialStages: [], initialShooters: [], initialResults: []);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: MainMenuView()),
      ),
    );

    await tester.pumpAndSettle();

    // Expect helper subtitle for Stage Input when empty
    expect(find.text('Add at least one stage and one shooter'), findsOneWidget);
  });

  testWidgets('Stage Input enabled when there is at least one stage and shooter', (WidgetTester tester) async {
    final repo = MatchRepository(
      initialStages: [MatchStage(stage: 1, scoringShoots: 5)],
      initialShooters: [Shooter(name: 'Alice', scaleFactor: 1.0)],
      initialResults: [],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: MainMenuView()),
      ),
    );

    await tester.pumpAndSettle();

    // When repository has entries, the helper subtitle should not be present
    expect(find.text('Add at least one stage and one shooter'), findsNothing);
  });
}
