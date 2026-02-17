import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';

void main() {
  testWidgets('plain-digit typing appends correctly (936 -> 9.36)', (WidgetTester tester) async {
    final repo = MatchRepository(
      initialStages: [MatchStage(stage: 1, scoringShoots: 1)],
      initialShooters: [Shooter(name: 'T', scaleFactor: 1.0)],
    );
    final vm = StageInputViewModel(repo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: repo),
          ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
        ],
        child: const MaterialApp(home: StageInputView()),
      ),
    );
    await tester.pumpAndSettle();

    // Select stage and shooter
    await tester.tap(find.byKey(const Key('stageSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stage 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shooterSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T').last);
    await tester.pumpAndSettle();

    // Simulate typing digits one-by-one by entering cumulative strings
    await tester.enterText(find.byKey(const Key('timeField')), '9');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('timeField')), '93');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('timeField')), '936');
    await tester.pumpAndSettle();

    // Verify displayed controller text and viewmodel value
    final tf = tester.widget<TextField>(find.byKey(const Key('timeField')));
    expect(tf.controller?.text, '9.36');
    expect(vm.time, closeTo(9.36, 0.0001));
  });
}
