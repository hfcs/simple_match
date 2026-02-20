import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/match_setup_view.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _MockPersistenceService extends PersistenceService {}

void main() {
  group('MatchSetupView edge/error coverage', () {
    testWidgets('Add, edit, cancel, remove, and error flows', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      final vm = MatchSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => repo),
            Provider(create: (_) => vm),
          ],
          child: const MaterialApp(home: MatchSetupView()),
        ),
      );
      // Add a stage
      await tester.enterText(find.byKey(const Key('stageField')), '1');
      await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
      await tester.tap(find.byKey(const Key('addStageButton')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Stage 1: 10 shoots'), findsOneWidget);
      // Edit the stage
      await tester.tap(find.byKey(const Key('editStage-1')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byKey(const Key('scoringShootsField')), '12');
      await tester.tap(find.byKey(const Key('confirmEditButton')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Stage 1: 12 shoots'), findsOneWidget);
      // Enter edit mode and cancel
      await tester.tap(find.byKey(const Key('editStage-1')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('addStageButton')), findsOneWidget);
      // Remove the stage (confirm dialog)
      await tester.tap(find.byKey(const Key('removeStage-1')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Remove'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Stage 1: 12 shoots'), findsNothing);
      // Add invalid input to trigger error
      await tester.enterText(find.byKey(const Key('stageField')), '');
      await tester.enterText(find.byKey(const Key('scoringShootsField')), '');
      await tester.tap(find.byKey(const Key('addStageButton')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Invalid input.'), findsOneWidget);
    });
  });
}
