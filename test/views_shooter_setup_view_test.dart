import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/shooter_setup_view.dart';

void main() {
  testWidgets('ShooterSetupView renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShooterSetupView()));
    expect(find.text('Shooter Setup'), findsOneWidget);
  });
}
