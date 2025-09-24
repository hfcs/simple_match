import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/main.dart';

void main() {
  testWidgets('Main menu navigation buttons push correct routes', (tester) async {
    await tester.pumpWidget(const MiniIPSCMatchApp());

    // Match Setup
    await tester.tap(find.text('Match Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Match Setup'), findsNWidgets(2)); // AppBar and body
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Shooter Setup
    await tester.tap(find.text('Shooter Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Shooter Setup'), findsNWidgets(2));
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Stage Input
    await tester.tap(find.text('Stage Input'));
    await tester.pumpAndSettle();
    expect(find.text('Stage Input'), findsNWidgets(2));
    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
