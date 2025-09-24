import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/match_setup_view.dart';

void main() {
  testWidgets('MatchSetupView renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatchSetupView()));
    expect(find.text('Match Setup'), findsOneWidget);
  });
}
