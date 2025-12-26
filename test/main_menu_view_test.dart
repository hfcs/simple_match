import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
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

    // Because MatchRepository expects typed model instances in production, we only need the lists' lengths for MainMenuView.
    // The repository constructor accepts maps via models in other code paths; for this widget test it's sufficient to provide non-empty lists.

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
