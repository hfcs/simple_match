import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/views/match_setup_view.dart';

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        Provider<MatchRepository>(create: (_) => MatchRepository()),
        ProxyProvider<MatchRepository, MatchSetupViewModel>(
          update: (_, repo, __) => MatchSetupViewModel(repo),
        ),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('MatchSetupView can remove a stage', (tester) async {
    await tester.pumpWidget(_wrap(const MatchSetupView()));
    // Add a stage
    await tester.enterText(find.byKey(const Key('stageField')), '2');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.text('Stage 2: 10 shoots'), findsOneWidget);
    // Remove it
    await tester.tap(find.byKey(const Key('removeStage-2')));
    await tester.pump();
    expect(find.text('Stage 2: 10 shoots'), findsNothing);
  });

  testWidgets('MatchSetupView can edit a stage', (tester) async {
    await tester.pumpWidget(_wrap(const MatchSetupView()));
    // Add a stage
    await tester.enterText(find.byKey(const Key('stageField')), '2');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    // Tap edit
    await tester.tap(find.byKey(const Key('editStage-2')));
    await tester.pump();
    // Change scoring shoots
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '12');
    await tester.tap(find.byKey(const Key('confirmEditButton')));
    await tester.pump();
    expect(find.text('Stage 2: 12 shoots'), findsOneWidget);
  });
}
