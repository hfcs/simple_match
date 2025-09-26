import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/main.dart' as app;
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('App starts and shows main menu', (tester) async {
    await tester.pumpWidget(app.MiniIPSCMatchApp(repository: MatchRepository()));
    expect(find.text('Mini IPSC Match'), findsOneWidget);
    expect(find.text('Match Setup'), findsOneWidget);
    expect(find.text('Shooter Setup'), findsOneWidget);
    expect(find.text('Stage Input'), findsOneWidget);
    expect(find.text('Stage Result'), findsOneWidget);
    expect(find.text('Overall Result'), findsOneWidget);
  });

  testWidgets('Navigation to Match Setup works', (tester) async {
    await tester.pumpWidget(app.MiniIPSCMatchApp(repository: MatchRepository()));
    await tester.tap(find.text('Match Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Match Setup'), findsWidgets);
  });

  testWidgets('Navigation to Shooter Setup works', (tester) async {
    await tester.pumpWidget(app.MiniIPSCMatchApp(repository: MatchRepository()));
    await tester.tap(find.text('Shooter Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Shooter Setup'), findsWidgets);
  });
}
