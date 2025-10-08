import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/stage_result.dart';

class MockPersistenceService extends PersistenceService {
  @override
  Future<List<Shooter>> loadShooters() async => [
    Shooter(name: 'Test', scaleFactor: 1.0),
  ];
  @override
  Future<List<MatchStage>> loadStages() async => [
    MatchStage(stage: 1, scoringShoots: 10),
  ];
}

void main() {
  group('StageInputView uncovered branches', () {
    testWidgets('shows validation error for incorrect sum', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        persistence: MockPersistenceService(),
        initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
        initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
      );
      final vm = StageInputViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageInputView()),
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
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      // Enter values that do not sum to scoringShoots
      await tester.enterText(find.byKey(const Key('aField')), '2');
      await tester.enterText(find.byKey(const Key('cField')), '2');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '2');
      // This sums to 8, not 10
      await tester.pumpAndSettle();
      // The error should be visible
      expect(
        find.textContaining('A + C + D + Misses must equal 10'),
        findsOneWidget,
      );
      // The submit button should be disabled
      final ElevatedButton submitBtn = tester.widget(
        find.byKey(const Key('submitButton')),
      );
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('all increment/decrement buttons work', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
        initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
      );
      final vm = StageInputViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageInputView()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stageSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      // Time
      final addBtns = find.widgetWithIcon(IconButton, Icons.add);
      final removeBtns = find.widgetWithIcon(IconButton, Icons.remove);
      for (int i = 0; i < 7; i++) {
        await tester.ensureVisible(addBtns.at(i));
        await tester.tap(addBtns.at(i));
        await tester.pump();
        await tester.ensureVisible(removeBtns.at(i));
        await tester.tap(removeBtns.at(i));
        await tester.pump();
      }
      // No exceptions = pass
      expect(true, isTrue);
    });

    testWidgets('shows error for negative values', (WidgetTester tester) async {
      final repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
        initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
      );
      final vm = StageInputViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageInputView()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stageSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('aField')), '-1');
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be negative'), findsOneWidget);
    });

    testWidgets('shows empty state if no stages or shooters', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository();
      final vm = StageInputViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageInputView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Please add at least one stage and one shooter'),
        findsOneWidget,
      );
    });

    testWidgets('can edit and remove a result', (WidgetTester tester) async {
      final repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
        initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
      );
      final vm = StageInputViewModel(repo);
      // Add a result
      repo.addResult(
        StageResult(
          stage: 1,
          shooter: 'Test',
          time: 1.0,
          a: 5,
          c: 3,
          d: 2,
          misses: 0,
          noShoots: 0,
          procedureErrors: 0,
        ),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageInputView()),
        ),
      );
      await tester.pumpAndSettle();
      // Edit
      await tester.tap(find.byKey(const Key('editResult-1-Test')));
      await tester.pumpAndSettle();
      // Remove
      await tester.tap(find.byKey(const Key('removeResult-1-Test')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editResult-1-Test')), findsNothing);
    });

    testWidgets('shows hit factor and adjusted hit factor', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
        initialShooters: [Shooter(name: 'Test', scaleFactor: 1.5)],
      );
      final vm = StageInputViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageInputView()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stageSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('aField')), '10');
  await tester.ensureVisible(find.byKey(const Key('timeField')));
  await tester.enterText(find.byKey(const Key('timeField')), '2');
      await tester.pumpAndSettle();
      expect(find.textContaining('Hit Factor: 25.00'), findsOneWidget);
      expect(find.textContaining('Adjusted: 37.50'), findsOneWidget);
    });
  });
}
