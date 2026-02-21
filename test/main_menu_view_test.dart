import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  testWidgets('MainMenu shows disabled items when empty and enables when data present', (tester) async {
    final repo = MatchRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: const MainMenuView(),
        ),
      ),
    );

    // Empty repo -> 'Nothing to clear' should be visible
    expect(find.text('Nothing to clear'), findsOneWidget);
    // Stage Input subtitle should mention add stage and shooter
    expect(find.textContaining('Add at least one stage'), findsOneWidget);

    // Add a stage and a shooter to enable Stage Input
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    await repo.addShooter(Shooter(name: 'T1'));
    // Rebuild UI
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    // Now 'Nothing to clear' should be gone and Stage Input enabled
    expect(find.text('Nothing to clear'), findsNothing);
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

    // When repository has entries, the helper subtitle should not be present
    expect(find.text('Add at least one stage and one shooter'), findsNothing);
  });
}
