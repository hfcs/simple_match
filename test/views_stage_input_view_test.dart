import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';


Widget _wrapWithProviders(Widget child, MatchRepository repo) {
  return ChangeNotifierProvider<MatchRepository>.value(
    value: repo,
    child: Provider<StageInputViewModel>(
      create: (context) => StageInputViewModel(repo),
      child: MaterialApp(home: child),
    ),
  );
}

void main() {
  testWidgets('accepts multi-digit input in all numeric fields', (tester) async {
    final repo = MatchRepository();
  repo.addShooter(Shooter(name: 'Alice', scaleFactor: 0.9));
  repo.addShooter(Shooter(name: 'Bob', scaleFactor: 1.0));
    repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
    repo.addStage(MatchStage(stage: 2, scoringShoots: 8));
    await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
    // Select stage and shooter
  await tester.tap(find.byKey(const Key('stageSelector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stage 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shooterSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice').last);
    await tester.pumpAndSettle();
    // Enter multi-digit values
    await tester.enterText(find.byKey(const Key('timeField')), '123.45');
    await tester.enterText(find.byKey(const Key('aField')), '12');
    await tester.enterText(find.byKey(const Key('cField')), '10');
    await tester.enterText(find.byKey(const Key('dField')), '8');
    await tester.enterText(find.byKey(const Key('missesField')), '7');
    await tester.enterText(find.byKey(const Key('noShootsField')), '6');
    await tester.enterText(find.byKey(const Key('procErrorsField')), '5');
    await tester.pump();
    expect(find.widgetWithText(TextField, '123.45'), findsOneWidget);
    expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    expect(find.widgetWithText(TextField, '10'), findsOneWidget);
    expect(find.widgetWithText(TextField, '8'), findsOneWidget);
    expect(find.widgetWithText(TextField, '7'), findsOneWidget);
    expect(find.widgetWithText(TextField, '6'), findsOneWidget);
    expect(find.widgetWithText(TextField, '5'), findsOneWidget);
  });
  group('StageInputView', () {
    late MatchRepository repo;
    setUp(() {
      repo = MatchRepository();
  repo.addShooter(Shooter(name: 'Alice', scaleFactor: 0.9));
  repo.addShooter(Shooter(name: 'Bob', scaleFactor: 1.0));
      repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
      repo.addStage(MatchStage(stage: 2, scoringShoots: 8));
    });

    testWidgets('renders all input fields and selectors', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      expect(find.byKey(const Key('stageSelector')), findsOneWidget);
      expect(find.byKey(const Key('shooterSelector')), findsOneWidget);
      expect(find.byKey(const Key('timeField')), findsOneWidget);
      expect(find.byKey(const Key('aField')), findsOneWidget);
      expect(find.byKey(const Key('cField')), findsOneWidget);
      expect(find.byKey(const Key('dField')), findsOneWidget);
      expect(find.byKey(const Key('missesField')), findsOneWidget);
      expect(find.byKey(const Key('noShootsField')), findsOneWidget);
      expect(find.byKey(const Key('procErrorsField')), findsOneWidget);
      expect(find.byKey(const Key('submitButton')), findsOneWidget);
    });

    testWidgets('disables submit if input is invalid', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter
  await tester.tap(find.byKey(const Key('stageSelector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();
      // Enter invalid values
      await tester.enterText(find.byKey(const Key('aField')), '3');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '3');
      await tester.enterText(find.byKey(const Key('missesField')), '2'); // 3+3+3+2=11 != 10
      await tester.pump();
      final submit = tester.widget<ElevatedButton>(find.byKey(const Key('submitButton')));
      expect(submit.enabled, isFalse);
      expect(find.textContaining('must equal'), findsOneWidget);
    });

    testWidgets('enables submit and displays hit factors when valid', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter
  await tester.tap(find.byKey(const Key('stageSelector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();
      // Enter valid values
      await tester.enterText(find.byKey(const Key('timeField')), '10.0');
      await tester.enterText(find.byKey(const Key('aField')), '5');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.enterText(find.byKey(const Key('noShootsField')), '0');
      await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
      await tester.pump();
      final submit = tester.widget<ElevatedButton>(find.byKey(const Key('submitButton')));
      expect(submit.enabled, isTrue);
      expect(find.textContaining('Hit Factor'), findsOneWidget);
      expect(find.textContaining('Adjusted'), findsOneWidget);
    });

    testWidgets('submits and displays in result list', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter
  await tester.tap(find.byKey(const Key('stageSelector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();
      // Enter valid values
      await tester.enterText(find.byKey(const Key('timeField')), '10.0');
      await tester.enterText(find.byKey(const Key('aField')), '5');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.enterText(find.byKey(const Key('noShootsField')), '0');
  await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
  await tester.pump();
  // Ensure submit button is visible before tapping
  await tester.ensureVisible(find.byKey(const Key('submitButton')));
  await tester.tap(find.byKey(const Key('submitButton')));
  await tester.pump();
  // Ensure results list is visible before checking
  await tester.ensureVisible(find.byKey(const Key('resultsList')));
  expect(find.text('Alice'), findsWidgets);
  expect(find.textContaining('Stage: 1'), findsWidgets); // Stage number in subtitle
  expect(find.textContaining('Time: 10.0'), findsWidgets); // Time in subtitle
    });

    testWidgets('can edit and remove a result', (tester) async {
  // Increase test environment size to avoid off-screen widget issues
  tester.binding.window.physicalSizeTestValue = const Size(1200, 1600);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Add a result
  await tester.tap(find.byKey(const Key('stageSelector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('timeField')), '10.0');
      await tester.enterText(find.byKey(const Key('aField')), '5');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.enterText(find.byKey(const Key('noShootsField')), '0');
      await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
      await tester.pump();
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();
  // Ensure results list is visible
      await tester.ensureVisible(find.byKey(const Key('resultsList')));
      // Tap edit
      await tester.ensureVisible(find.byKey(const Key('editResult-1-Alice')));
      await tester.tap(find.byKey(const Key('editResult-1-Alice')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('aField')), '4');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('submitButton')));
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();
      expect(find.text('4'), findsWidgets);
      // Tap remove
      await tester.ensureVisible(find.byKey(const Key('removeResult-1-Alice')));
      await tester.tap(find.byKey(const Key('removeResult-1-Alice')));
      await tester.pumpAndSettle();
      // Only check that Alice is not present in the results list (no ListTile with her name)
      final resultTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(resultTiles.where((tile) => (tile.title as Text).data == 'Alice'), isEmpty);
      // Reset test environment size
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  });
}
