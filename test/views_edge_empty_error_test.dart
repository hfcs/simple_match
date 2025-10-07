import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/match_setup_view.dart';
import 'package:simple_match/views/shooter_setup_view.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/services/persistence_service.dart';

// Mock PersistenceService for StageResultViewModel test
class _MockPersistenceService extends PersistenceService {
  @override
  Future<List<StageResult>> loadStageResults() async => [];
  @override
  Future<List<Shooter>> loadShooters() async => [];
  @override
  Future<List<MatchStage>> loadStages() async => [
    MatchStage(stage: 1, scoringShoots: 5),
  ];
}

void main() {
  group('Widget edge/empty/error coverage', () {
    testWidgets('MatchSetupView renders with no stages', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>.value(value: repo),
            Provider<MatchSetupViewModel>.value(
              value: MatchSetupViewModel(repo),
            ),
          ],
          child: const MaterialApp(home: MatchSetupView()),
        ),
      );
      expect(find.text('Stages:'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('ShooterSetupView renders with no shooters', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>.value(value: repo),
            Provider<ShooterSetupViewModel>.value(
              value: ShooterSetupViewModel(repo),
            ),
          ],
          child: const MaterialApp(home: ShooterSetupView()),
        ),
      );
      expect(find.text('Shooters:'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('StageResultView shows no results for stage', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
      final vm = StageResultViewModel(
        persistenceService: _MockPersistenceService(),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>.value(value: repo),
            ChangeNotifierProvider<StageResultViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: StageResultView(viewModel: vm)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No results for this stage.'), findsOneWidget);
    });

    testWidgets('OverallResultView shows no results yet', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>.value(value: repo),
            Provider<OverallResultViewModel>.value(
              value: OverallResultViewModel(repo),
            ),
          ],
          child: const MaterialApp(home: OverallResultView()),
        ),
      );
      expect(find.text('No results yet.'), findsOneWidget);
    });

    testWidgets('StageInputView shows empty state and validation error', (
      tester,
    ) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      // Add stage and shooter BEFORE building the widget
      repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
      repo.addShooter(Shooter(name: 'A', scaleFactor: 1.0));
      final vm = StageInputViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>.value(value: repo),
            ChangeNotifierProvider<StageInputViewModel>.value(value: vm),
          ],
          child: const MaterialApp(home: StageInputView()),
        ),
      );
      // Ensure dropdowns are present before tapping
      expect(find.byKey(const Key('stageSelector')), findsOneWidget);
      expect(find.byKey(const Key('shooterSelector')), findsOneWidget);
      // Select stage and shooter in dropdowns
      await tester.tap(find.byKey(const Key('stageSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stage 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shooterSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();
      // Enter valid values for A, C, D, Misses so sum is correct
      await tester.enterText(find.byKey(const Key('aField')), '2');
      await tester.enterText(find.byKey(const Key('cField')), '2');
      await tester.enterText(find.byKey(const Key('dField')), '1');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.pumpAndSettle();
      // Now set time to 0 to trigger time validation error
      await tester.enterText(find.byKey(const Key('timeField')), '0');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Time must be greater than 0'),
        findsOneWidget,
      );
    });
  });
}
