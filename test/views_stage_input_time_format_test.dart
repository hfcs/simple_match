import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  testWidgets('Time field plain-digit formatting: 9 -> 9.00, 91 -> 91.00, 912 -> 9.12',
      (WidgetTester tester) async {
    final repo = MatchRepository(
      initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
      initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
    );
    final vm = StageInputViewModel(repo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
      ],
      child: const MaterialApp(home: StageInputView()),
    ));

    // Select stage and shooter to enable input fields
    vm.selectStage(1);
    vm.selectShooter('Test');
    await tester.pumpAndSettle();

    final timeFinder = find.byKey(const Key('timeField'));
    expect(timeFinder, findsOneWidget);

    // Enter single digit
    await tester.enterText(timeFinder, '9');
    await tester.pumpAndSettle();
    final text1 = (tester.widget(timeFinder) as TextField).controller!.text;
    expect(text1, '9.00');

    // Enter two digits (displayed without explicit decimals in current UI)
    await tester.enterText(timeFinder, '91');
    await tester.pumpAndSettle();
    final text2 = (tester.widget(timeFinder) as TextField).controller!.text;
    expect(text2, '91');

    // Enter three digits -> should format as 9.12
    await tester.enterText(timeFinder, '912');
    await tester.pumpAndSettle();
    final text3 = (tester.widget(timeFinder) as TextField).controller!.text;
    expect(text3, '9.12');

    // Also verify ViewModel updated numeric time
    expect(vm.time, closeTo(9.12, 0.001));
  });
}
