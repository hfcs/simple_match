import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/main.dart' as app;
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('App starts and shows main menu', (tester) async {
    await tester.pumpWidget(
      app.MiniIPSCMatchApp(repository: MatchRepository()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Mini IPSC Match'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('Navigation to Match Setup works', (tester) async {
    await tester.pumpWidget(
      app.MiniIPSCMatchApp(repository: MatchRepository()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Match Setup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Match Setup'), findsWidgets);
  });

  testWidgets('Navigation to Shooter Setup works', (tester) async {
    await tester.pumpWidget(
      app.MiniIPSCMatchApp(repository: MatchRepository()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Shooter Setup'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Shooter Setup'), findsWidgets);
  });
}
