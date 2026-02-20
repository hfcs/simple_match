import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  testWidgets('OverallResultView shows no-results and lists results when present', (tester) async {
    final repo = MatchRepository();
    // No results -> shows 'No results yet.'
    await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo, child: const OverallResultView())));
    await tester.pumpAndSettle();
    expect(find.text('No results yet.'), findsOneWidget);

    // Add shooter and result to produce a non-empty result set
    await repo.addShooter(Shooter(name: 'S1'));
    await repo.addResult(StageResult(stage: 1, shooter: 'S1', time: 10.0, a: 5, c: 0, d: 0));
    await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo, child: const OverallResultView())));
    await tester.pumpAndSettle();

    // Expect to find the shooter's name in the list
    expect(find.text('S1'), findsWidgets);
    // If results exist, export IconButton should be present (but we won't tap it)
    expect(find.byIcon(Icons.picture_as_pdf), findsWidgets);
  });
}
