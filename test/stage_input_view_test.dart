import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  testWidgets('StageInputView prompts when no data and shows inputs when data present', (tester) async {
    final repo = MatchRepository();
    // Create a single VM instance and use ChangeNotifierProvider.value so we
    // don't rebuild the provider with different constructors later in the
    // same test (which can cause provider to throw during rebuilds).
    final vm = StageInputViewModel(repo);
    await tester.pumpWidget(MaterialApp(home: Provider.value(value: repo, child: ChangeNotifierProvider.value(value: vm, child: const StageInputView()))));
    await tester.pumpAndSettle();

    // With no stages/shooters, prompt is shown
    expect(find.textContaining('Please add at least one stage'), findsOneWidget);

    // Add stage and shooter
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    await repo.addShooter(Shooter(name: 'Shooter1'));

    // Reuse the same `vm` instance created above so provider constructors
    // remain consistent across pumps.
    await tester.pumpWidget(MaterialApp(home: Provider.value(value: repo, child: ChangeNotifierProvider.value(value: vm, child: const StageInputView()))));
    await tester.pumpAndSettle();

    // Select stage and shooter via the viewmodel
    vm.selectStage(1);
    vm.selectShooter('Shooter1');
    await tester.pumpAndSettle();

    // Give the widget tree a final chance to settle in the full-suite run
    // (some earlier tests mutate globals/state that can cause small timing
    //  differences when the entire suite runs). A brief pump makes this
    //  assertion deterministic.
    await tester.pump(const Duration(milliseconds: 50));
    // Now time field should exist and be enabled
    expect(find.byKey(const Key('timeField')), findsOneWidget);
  });
}
