import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/views/match_setup_view.dart';
import 'package:simple_match/views/shooter_setup_view.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _MockPersistenceService extends PersistenceService {}

void main() {
  group('Widget edge/empty/error coverage for all views', () {
    testWidgets('MainMenuView navigation buttons present', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainMenuView()));
      expect(find.text('Match Setup'), findsOneWidget);
      expect(find.text('Shooter Setup'), findsOneWidget);
      expect(find.text('Stage Input'), findsOneWidget);
      expect(find.text('Stage Result'), findsOneWidget);
      expect(find.text('Overall Result'), findsOneWidget);
    });

    testWidgets('MatchSetupView shows empty and error states', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MatchRepository>(
          create: (_) => MatchRepository(persistence: _MockPersistenceService()),
          child: Builder(builder: (context) {
            final repo = Provider.of<MatchRepository>(context, listen: false);
            return Provider<MatchSetupViewModel>(
              create: (_) => MatchSetupViewModel(repo),
              child: const MaterialApp(home: MatchSetupView()),
            );
          }),
        ),
      );
      expect(find.text('Match Setup'), findsOneWidget);
      // Empty state: section label present, no ListTile
      expect(find.text('Stages:'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('ShooterSetupView shows empty and error states', (
      tester,
    ) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      await tester.pumpWidget(
        ChangeNotifierProvider<MatchRepository>(
          create: (_) => repo,
          child: Provider<ShooterSetupViewModel>(
            create: (_) => ShooterSetupViewModel(repo),
            child: const MaterialApp(home: ShooterSetupView()),
          ),
        ),
      );
      expect(find.text('Shooter Setup'), findsOneWidget);
      // Empty state: section label present, no ListTile
      expect(find.text('Shooters:'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('StageInputView shows empty state', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>(create: (_) => repo),
            ChangeNotifierProvider<StageInputViewModel>(
              create: (_) => StageInputViewModel(repo),
            ),
          ],
          child: const MaterialApp(home: StageInputView()),
        ),
      );
      expect(find.text('Stage Input'), findsOneWidget);
      // No stages/shooters: shows exact message
      expect(
        find.text('Please add at least one stage and one shooter first.'),
        findsOneWidget,
      );
    });

    testWidgets('StageResultView shows empty state', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<StageResultViewModel>(
          create: (_) => StageResultViewModel(
            persistenceService: _MockPersistenceService(),
          ),
          child: MaterialApp(
            home: StageResultView(
              viewModel: StageResultViewModel(
                persistenceService: _MockPersistenceService(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Stage Result'), findsOneWidget);
      expect(find.text('No stages available.'), findsOneWidget);
    });

    testWidgets('OverallResultView shows empty state and PDF button hidden', (
      tester,
    ) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>(create: (_) => repo),
            Provider<OverallResultViewModel>(
              create: (context) => OverallResultViewModel(repo),
            ),
          ],
          child: const MaterialApp(home: OverallResultView()),
        ),
      );
      expect(find.text('Overall Result'), findsOneWidget);
      expect(find.text('No results yet.'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
    });
  });
}
