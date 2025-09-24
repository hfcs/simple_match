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
  testWidgets('MatchSetupView handles min/max and invalid input', (tester) async {
    await tester.pumpWidget(_wrap(const MatchSetupView()));
    // Min valid
    await tester.enterText(find.byKey(const Key('stageField')), '1');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '1');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.text('Stage 1: 1 shoots'), findsOneWidget);
    // Max valid
    await tester.enterText(find.byKey(const Key('stageField')), '30');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '32');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.text('Stage 30: 32 shoots'), findsOneWidget);
    // Invalid: negative
    await tester.enterText(find.byKey(const Key('stageField')), '-1');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.textContaining('between 1 and 30'), findsOneWidget);
    // Invalid: over max
    await tester.enterText(find.byKey(const Key('stageField')), '31');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.textContaining('between 1 and 30'), findsOneWidget);
    // Invalid: non-integer
    await tester.enterText(find.byKey(const Key('stageField')), 'abc');
    await tester.enterText(find.byKey(const Key('scoringShootsField')), '10');
    await tester.tap(find.byKey(const Key('addStageButton')));
    await tester.pump();
    expect(find.textContaining('Invalid input.'), findsOneWidget);
  });
}
