import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';

void main() {
  group('StageInputView additional edge cases', () {
    testWidgets('Rapid field changes and focus loss do not break state', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 5)],
        initialShooters: [Shooter(name: 'Edge', scaleFactor: 1.0)],
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
      await tester.tap(
        find.byKey(const Key('stageSelector')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stage 1').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('shooterSelector')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edge').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      // Rapidly change A, C, D fields
      await tester.enterText(find.byKey(const Key('aField')), '2');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('cField')), '2');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('dField')), '1');
      await tester.pump();
      // Move focus away
      await tester.tap(find.byKey(const Key('timeField')), warnIfMissed: false);
      await tester.pump();
      // Should not throw and state should be correct
      expect(vm.a, 2);
      expect(vm.c, 2);
      expect(vm.d, 1);
      // Now enter invalid value and blur
      await tester.enterText(find.byKey(const Key('aField')), '-5');
      await tester.pump();
      await tester.tap(find.byKey(const Key('timeField')));
      await tester.pump();
      expect(find.textContaining('cannot be negative'), findsOneWidget);
    });

    testWidgets('All error messages for each field are shown as expected', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 2)],
        initialShooters: [Shooter(name: 'Err', scaleFactor: 1.0)],
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
      await tester.tap(
        find.byKey(const Key('stageSelector')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stage 1').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('shooterSelector')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Err').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      // Enter negative for each field and check error
      final fields = [
        'aField',
        'cField',
        'dField',
        'missesField',
        'noShootsField',
        'procErrorsField',
        'timeField',
      ];
      for (final key in fields) {
        await tester.enterText(find.byKey(Key(key)), '-1');
        await tester.pump();
        expect(find.textContaining('cannot be negative'), findsOneWidget);
        // Reset to 0 for next field
        await tester.enterText(find.byKey(Key(key)), '0');
        await tester.pump();
      }
    });
  });
}
