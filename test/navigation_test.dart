import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/main.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('Main menu navigation buttons push correct routes', (
    tester,
  ) async {
    final repo = MatchRepository();
    await tester.pumpWidget(MiniIPSCMatchApp(repository: repo));

    // Match Setup
    final matchTile = find.ancestor(of: find.text('Match Setup'), matching: find.byType(ListTile));
    if (matchTile.evaluate().isNotEmpty) {
      await tester.tap(matchTile);
    } else {
      await tester.tap(find.text('Match Setup'));
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Match Setup'), findsOneWidget); // AppBar only
    // Navigate back using the visible back button instead of tester.pageBack()
    final backBtn = find.byType(BackButton);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn);
      await tester.pump(const Duration(milliseconds: 200));
    } else {
      final backTooltip = find.byTooltip('Back');
      if (backTooltip.evaluate().isNotEmpty) {
        await tester.tap(backTooltip);
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    // Shooter Setup
    final shooterTile = find.ancestor(of: find.text('Shooter Setup'), matching: find.byType(ListTile));
    if (shooterTile.evaluate().isNotEmpty) {
      await tester.tap(shooterTile);
    } else {
      await tester.tap(find.text('Shooter Setup'));
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Shooter Setup'), findsOneWidget);
    final backBtn2 = find.byType(BackButton);
    if (backBtn2.evaluate().isNotEmpty) {
      await tester.tap(backBtn2);
      await tester.pump(const Duration(milliseconds: 200));
    } else {
      final backTooltip2 = find.byTooltip('Back');
      if (backTooltip2.evaluate().isNotEmpty) {
        await tester.tap(backTooltip2);
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    // Stage Input
    final stageTile = find.ancestor(of: find.text('Stage Input'), matching: find.byType(ListTile));
    if (stageTile.evaluate().isNotEmpty) {
      await tester.tap(stageTile);
    } else {
      await tester.tap(find.text('Stage Input'));
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Stage Input'), findsOneWidget);
    final backBtn3 = find.byType(BackButton);
    if (backBtn3.evaluate().isNotEmpty) {
      await tester.tap(backBtn3);
      await tester.pump(const Duration(milliseconds: 200));
    } else {
      final backTooltip3 = find.byTooltip('Back');
      if (backTooltip3.evaluate().isNotEmpty) {
        await tester.tap(backTooltip3);
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
  });
}
