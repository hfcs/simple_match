import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';

void main() {
  testWidgets('DNF/DQ and roRemark persistence', (tester) async {
    final repo = MatchRepository(
      initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
      initialShooters: [Shooter(name: 'Zoe', scaleFactor: 1.0)],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MatchRepository>.value(value: repo),
          ChangeNotifierProvider<StageInputViewModel>(
            create: (context) => StageInputViewModel(repo),
          ),
        ],
        child: MaterialApp(home: StageInputView()),
      ),
    );
    await tester.pumpAndSettle();

    // select stage and shooter
    await tester.tap(find.byKey(const Key('stageSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stage 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shooterSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zoe').last);
    await tester.pumpAndSettle();

  // choose DNF (tap the RadioListTile itself to avoid hitting text-only render issues)
  final dnfFinder = find.widgetWithText(RadioListTile<String>, 'DNF');
  expect(dnfFinder, findsOneWidget);
  await tester.ensureVisible(dnfFinder);
  await tester.tap(dnfFinder);
  await tester.pumpAndSettle();

    // enter roRemark
    await tester.enterText(find.byKey(const Key('roRemarkField')), 'Safety issue');
    await tester.pumpAndSettle();

    // submit
    await tester.ensureVisible(find.byKey(const Key('submitButton')));
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();

    // ensure repo updated
    expect(repo.results.length, 1);
    final r = repo.results.first;
    expect(r.status, 'DNF');
    expect(r.roRemark, 'Safety issue');
    expect(r.time, 0.0);
    expect(r.a, 0);
    expect(r.c, 0);
    expect(r.d, 0);
  });
}
