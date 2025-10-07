import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  group('OverallResultView PDF Export', () {
    testWidgets(
      'shows PDF export button when results exist and triggers on tap',
      (WidgetTester tester) async {
        final repo = MatchRepository();
        repo.addShooter(Shooter(name: 'Alice', scaleFactor: 1.0));
        repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
        repo.addResult(
          StageResult(
            stage: 1,
            shooter: 'Alice',
            time: 10.0,
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
              ChangeNotifierProvider(create: (_) => repo),
              ProxyProvider<MatchRepository, OverallResultViewModel>(
                update: (_, repo, __) => OverallResultViewModel(repo),
              ),
            ],
            child: const MaterialApp(home: OverallResultView()),
          ),
        );
        await tester.pumpAndSettle();

        // PDF export button should be present
        final pdfButton = find.byIcon(Icons.picture_as_pdf);
        expect(pdfButton, findsOneWidget);

        // Tap the button (should not throw)
        await tester.tap(pdfButton);
        // No need to check actual PDF output, just that the button is tappable
      },
    );

    testWidgets('does not show PDF export button when no results', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => repo),
            ProxyProvider<MatchRepository, OverallResultViewModel>(
              update: (_, repo, __) => OverallResultViewModel(repo),
            ),
          ],
          child: const MaterialApp(home: OverallResultView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
    });
  });
}
