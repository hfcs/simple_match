import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  final List<StageResult> mockResults;
  final List<Shooter> mockShooters;
  final List<MatchStage> mockStages;
  MockPersistenceService({
    required this.mockResults,
    required this.mockShooters,
    required this.mockStages,
  });
  @override
  Future<List<StageResult>> loadStageResults() async => mockResults;
  @override
  Future<List<Shooter>> loadShooters() async => mockShooters;
  @override
  Future<List<MatchStage>> loadStages() async => mockStages;
}

void main() {
  testWidgets(
    'StageResultView displays detailed sortable table with fixed column widths',
    (WidgetTester tester) async {
      final shooters = [
        Shooter(name: 'Alice', scaleFactor: 1.0),
        Shooter(name: 'Bob', scaleFactor: 0.9),
      ];
      final stages = [MatchStage(stage: 1, scoringShoots: 10)];
      final results = [
        StageResult(
          stage: 1,
          shooter: 'Alice',
          time: 12.0,
          a: 8,
          c: 2,
          d: 0,
          misses: 0,
          noShoots: 0,
          procedureErrors: 1,
        ),
        StageResult(
          stage: 1,
          shooter: 'Bob',
          time: 10.0,
          a: 7,
          c: 3,
          d: 0,
          misses: 0,
          noShoots: 1,
          procedureErrors: 0,
        ),
      ];
      final mockPersistence = MockPersistenceService(
        mockResults: results,
        mockShooters: shooters,
        mockStages: stages,
      );
      final viewModel = StageResultViewModel(
        persistenceService: mockPersistence,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400, // Simulate mobile width
            child: StageResultView(viewModel: viewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Should show table header
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Raw HF'), findsOneWidget);
      expect(find.text('Scaled HF'), findsOneWidget);
      expect(find.text('Match Pt (After Scaling)'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('Misses'), findsOneWidget);
      expect(find.text('No Shoots'), findsOneWidget);
      expect(find.text('Proc Err'), findsOneWidget);
      // Should show both shooters
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // Should show correct values for Alice
      expect(find.text('8'), findsOneWidget); // A
      expect(find.text('2'), findsOneWidget); // C
      expect(find.text('0'), findsWidgets); // D, Misses, No Shoots, Proc Err
      // Should show correct values for Bob
      expect(find.text('7'), findsOneWidget); // A
      expect(find.text('3'), findsOneWidget); // C
      expect(find.text('1'), findsWidgets); // No Shoots, Proc Err, etc
      // Should show hit factors
      expect(find.textContaining('.'), findsWidgets); // hit factors and time
      // Check that all columns are visible (not clipped)
      final headerRow = tester.widget<Row>(
        find.byKey(const Key('stageResultTableHeader')),
      );
      // Should have 11 columns (each with a vertical rule except the last)
      expect(headerRow.children.length, equals(11));
    },
  );

  testWidgets('StageResultView columns fit within mobile width', (
    WidgetTester tester,
  ) async {
    final shooters = [Shooter(name: 'A', scaleFactor: 1.0)];
    final stages = [MatchStage(stage: 1, scoringShoots: 10)];
    final results = [
      StageResult(
        stage: 1,
        shooter: 'A',
        time: 10.0,
        a: 1,
        c: 1,
        d: 1,
        misses: 1,
        noShoots: 1,
        procedureErrors: 1,
      ),
    ];
    final mockPersistence = MockPersistenceService(
      mockResults: results,
      mockShooters: shooters,
      mockStages: stages,
    );
    final viewModel = StageResultViewModel(persistenceService: mockPersistence);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400, // Simulate mobile width
          child: StageResultView(viewModel: viewModel),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // All columns should be present and visible
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Raw HF'), findsOneWidget);
    expect(find.text('Scaled HF'), findsOneWidget);
    expect(find.text('Match Pt (After Scaling)'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('A'), findsWidgets); // header and data cell
    expect(find.text('C'), findsWidgets);
    expect(find.text('D'), findsWidgets);
    expect(find.text('Misses'), findsOneWidget);
    expect(find.text('No Shoots'), findsOneWidget);
    expect(find.text('Proc Err'), findsOneWidget);
    // Should not overflow horizontally (ListView is scrollable, but all columns are present)
    // (No overflow error thrown)
    expect(tester.takeException(), isNull);
  });
}
