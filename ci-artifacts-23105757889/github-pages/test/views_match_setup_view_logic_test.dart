import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/views/match_setup_view.dart';

Widget _wrap(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider<MatchRepository>(create: (_) => MatchRepository()),
    ProxyProvider<MatchRepository, MatchSetupViewModel>(
      update: (_, repo, __) => MatchSetupViewModel(repo),
    ),
  ],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('MatchSetupView adds and displays a stage', (tester) async {
    await tester.pumpWidget(_wrap(const MatchSetupView()));
    // Enter valid stage and scoring shoots
    await tester.enterText(find.byKey(const Key('stageField')), '2');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    // Should display in the list
    expect(find.text('Stage 2: 10 shoots'), findsOneWidget);
  });

  testWidgets('MatchSetupView rejects duplicate and invalid input', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const MatchSetupView()));
    // Add valid
    await tester.enterText(find.byKey(const Key('stageField')), '2');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    // Try duplicate
    await tester.enterText(find.byKey(const Key('stageField')), '2');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '12');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.textContaining('already exists'), findsOneWidget);
    // Try out of range
    await tester.enterText(find.byKey(const Key('stageField')), '0');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.textContaining('between 1 and 30'), findsOneWidget);
  });
}
