import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  group('StageInputView uncovered UI/logic', () {
    late MatchRepository repo;
    late StageInputViewModel vm;

    setUp(() {
      repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 8)],
        initialShooters: [Shooter(name: 'Alice', scaleFactor: 1.0)],
      );
      vm = StageInputViewModel(repo);
    });

    Widget buildTestWidget() => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
      ],
      child: const MaterialApp(home: StageInputView()),
    );

    testWidgets('Procedure Errors increment/decrement and validation', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      // Select stage and shooter programmatically to avoid popup tap flakiness
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));

      // Find procedure errors field and ensure visible
      final procErrorsField = find.byKey(const Key('procErrorsField'));
      expect(procErrorsField, findsOneWidget);
      await tester.ensureVisible(procErrorsField);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(procErrorsField, '2');
      await tester.pump();
      expect(vm.procErrors, 2);

      // Find the parent Row of the procErrorsField
      final procErrorsRow = find.ancestor(
        of: procErrorsField,
        matching: find.byType(Row),
      );
      // Decrement using button (first IconButton in the row)
      final decBtn = find.descendant(
        of: procErrorsRow,
        matching: find.widgetWithIcon(IconButton, Icons.remove),
      );
      await tester.ensureVisible(decBtn);
      await tester.tap(decBtn);
      await tester.pump();
      expect(vm.procErrors, 1);

      // Increment using button (last IconButton in the row)
      final incBtn = find.descendant(
        of: procErrorsRow,
        matching: find.widgetWithIcon(IconButton, Icons.add),
      );
      await tester.ensureVisible(incBtn);
      await tester.tap(incBtn);
      await tester.pump();
      expect(vm.procErrors, 2);
    });

    testWidgets('Shows error if submit with invalid (negative) values', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 200));
      // Select stage and shooter programmatically to avoid popup tap flakiness
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));

      // Enter negative value for A
      final aField = find.byKey(const Key('aField'));
      await tester.ensureVisible(aField);
      await tester.enterText(aField, '-1');
      await tester.pump();
      expect(vm.a, -1);

      // Try to submit
      final submitBtn = find.byKey(const Key('submitButton'));
      await tester.ensureVisible(submitBtn);
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.textContaining('cannot be negative'), findsOneWidget);
    });
  });
}
