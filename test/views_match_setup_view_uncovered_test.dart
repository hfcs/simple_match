import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/match_setup_view.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  @override
  Future<List<MatchStage>> loadStages() async => [MatchStage(stage: 1, scoringShoots: 10)];
}

void main() {
  group('MatchSetupView uncovered branches', () {
    testWidgets('shows error for duplicate stage', (WidgetTester tester) async {
      final repo = MatchRepository(
        persistence: MockPersistenceService(),
        initialStages: [MatchStage(stage: 1, scoringShoots: 10)],
        initialShooters: [],
      );
      final vm = MatchSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            Provider<MatchSetupViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: MatchSetupView()),
        ),
      );
      await tester.pumpAndSettle();
      // Try to add duplicate stage
  await tester.enterText(find.byKey(const Key('stageField')), '1');
  await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
  await tester.tap(find.byKey(const Key('addStageButton')));
  await tester.pumpAndSettle();
  expect(find.textContaining('already exists'), findsOneWidget);
    });

    testWidgets('shows error for invalid stage number', (WidgetTester tester) async {
      final repo = MatchRepository(
        persistence: MockPersistenceService(),
        initialStages: [],
        initialShooters: [],
      );
      final vm = MatchSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            Provider<MatchSetupViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: MatchSetupView()),
        ),
      );
      await tester.pumpAndSettle();
      // Enter invalid stage number
  await tester.enterText(find.byKey(const Key('stageField')), 'abc');
  await tester.tap(find.byKey(const Key('addStageButton')));
  await tester.pumpAndSettle();
  expect(find.text('Invalid input.'), findsOneWidget);
    });

    testWidgets('shows error for invalid scoring shoots', (WidgetTester tester) async {
      final repo = MatchRepository(
        persistence: MockPersistenceService(),
        initialStages: [],
        initialShooters: [],
      );
      final vm = MatchSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            Provider<MatchSetupViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: MatchSetupView()),
        ),
      );
      await tester.pumpAndSettle();
      // Enter invalid scoring shoots
  await tester.enterText(find.byKey(const Key('stageField')), '2');
  await tester.enterText(find.byKey(const Key('scoringShootsField')), 'abc');
  await tester.tap(find.byKey(const Key('addStageButton')));
  await tester.pumpAndSettle();
  expect(find.text('Invalid input.'), findsOneWidget);
    });
      testWidgets('shows error on invalid input and empty state', (tester) async {
        final repo = MatchRepository(persistence: PersistenceService());
        await tester.pumpWidget(
          Provider<MatchSetupViewModel>(
            create: (_) => MatchSetupViewModel(repo),
            child: const MaterialApp(home: MatchSetupView()),
          ),
        );
        // Try to add with invalid input
        await tester.enterText(find.byKey(const Key('stageField')), '');
        await tester.enterText(find.byKey(const Key('scoringShootsField')), '');
        await tester.tap(find.byKey(const Key('addStageButton')));
        await tester.pump();
        expect(find.textContaining('Invalid'), findsOneWidget);
        // Should show empty state (no stages)
        expect(find.text('Stages:'), findsOneWidget);
      });
  });
}
