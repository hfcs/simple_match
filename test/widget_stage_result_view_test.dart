import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  List<Shooter> shooters;
  List<MatchStage> stages;
  List<StageResult> results;
  MockPersistenceService({required this.shooters, required this.stages, required this.results});
  @override
  Future<List<Shooter>> loadShooters() async => shooters;
  @override
  Future<List<MatchStage>> loadStages() async => stages;
  @override
  Future<List<StageResult>> loadStageResults() async => results;
}

void main() {
  testWidgets('StageResultView shows results for first stage when selected', (WidgetTester tester) async {
    final shooters = [
      Shooter(name: 'Alice', scaleFactor: 1.0),
      Shooter(name: 'Bob', scaleFactor: 1.5),
    ];
    final stages = [
      MatchStage(stage: 1, scoringShoots: 10),
      MatchStage(stage: 2, scoringShoots: 8),
    ];
    final results = [
      StageResult(stage: 1, shooter: 'Alice', time: 10, a: 5, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
      StageResult(stage: 1, shooter: 'Bob', time: 8, a: 6, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
    ];
    final vm = StageResultViewModel(persistenceService: MockPersistenceService(
      shooters: shooters,
      stages: stages,
      results: results,
    ));
    await tester.pumpWidget(
      MaterialApp(
        home: StageResultView(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();
    // Should show results for Stage 1
    // The header row and dropdown both have 'Stage 1', so just check for result rows
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('No results for this stage.'), findsNothing);
    // Check that hit factor and adjusted columns are present
    expect(find.text('Hit Factor', skipOffstage: false), findsOneWidget);
    expect(find.text('Adjusted', skipOffstage: false), findsOneWidget);
  });
  testWidgets('StageResultView displays ranked results for each stage', (WidgetTester tester) async {
    final shooters = [
      Shooter(name: 'Alice', scaleFactor: 1.0),
      Shooter(name: 'Bob', scaleFactor: 1.5),
    ];
    final stages = [
      MatchStage(stage: 1, scoringShoots: 10),
      MatchStage(stage: 2, scoringShoots: 8),
    ];
    final results = [
      StageResult(stage: 1, shooter: 'Alice', time: 10, a: 5, c: 3, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
      StageResult(stage: 1, shooter: 'Bob', time: 8, a: 6, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
      StageResult(stage: 2, shooter: 'Alice', time: 9, a: 4, c: 2, d: 2, misses: 0, noShoots: 0, procedureErrors: 0),
    ];
    final vm = StageResultViewModel(persistenceService: MockPersistenceService(
      shooters: shooters,
      stages: stages,
      results: results,
    ));
    await tester.pumpWidget(
      MaterialApp(
        home: StageResultView(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();
  // Check that both shooters are displayed for stage 1
  expect(find.text('Bob'), findsOneWidget);
  expect(find.text('Alice'), findsOneWidget);
  // Switch to stage 2
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stage 2').last);
  await tester.pumpAndSettle();
  // Only Alice should be present for stage 2
  expect(find.text('Bob'), findsNothing);
  expect(find.text('Alice'), findsOneWidget);
  // Check hit factor and adjusted columns are present
  expect(find.text('Hit Factor', skipOffstage: false), findsOneWidget);
  expect(find.text('Adjusted', skipOffstage: false), findsOneWidget);
  });
}
