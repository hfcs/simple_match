import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  testWidgets('Clear All Data button clears repository after confirmation', (tester) async {
    final repo = MatchRepository();
    // Add some data
    repo.addShooter(Shooter(name: 'Alice'));
    repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
    repo.addResult(StageResult(stage: 1, shooter: 'Alice', time: 10, a: 5, c: 3, d: 2));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: MainMenuView()),
      ),
    );

    // Tap Clear All Data
    await tester.tap(find.widgetWithText(ElevatedButton, 'Clear All Data'));
    await tester.pumpAndSettle();
    // Confirm dialog appears
    expect(find.text('Are you sure you want to clear all data? This cannot be undone.'), findsOneWidget);
    // Tap Confirm
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();
    // SnackBar appears
    expect(find.text('All data cleared.'), findsOneWidget);
    // Data should be cleared
    expect(repo.shooters, isEmpty);
    expect(repo.stages, isEmpty);
    expect(repo.results, isEmpty);
  });
}
