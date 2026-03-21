import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  testWidgets('dump main menu with data', (tester) async {
    final repo = MatchRepository();
    repo.addShooter(Shooter(name: 'Alice'));
    repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
    repo.addResult(
      StageResult(stage: 1, shooter: 'Alice', time: 10, a: 5, c: 3, d: 2),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: MainMenuView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    debugDumpApp();
  });
}
