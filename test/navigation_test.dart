import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/main.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('Main menu navigation buttons push correct routes', (tester) async {
    final repo = MatchRepository();
    await tester.pumpWidget(MiniIPSCMatchApp(repository: repo));

    // Match Setup
    await tester.tap(find.text('Match Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Match Setup'), findsOneWidget); // AppBar only
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Shooter Setup
    await tester.tap(find.text('Shooter Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Shooter Setup'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Stage Input
    await tester.tap(find.text('Stage Input'));
    await tester.pumpAndSettle();
    expect(find.text('Stage Input'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
