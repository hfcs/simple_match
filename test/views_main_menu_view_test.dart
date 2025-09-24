import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/main_menu_view.dart';

void main() {
  testWidgets('MainMenuView renders all buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuView()));
    expect(find.text('Match Setup'), findsOneWidget);
    expect(find.text('Shooter Setup'), findsOneWidget);
    expect(find.text('Stage Input'), findsOneWidget);
    expect(find.text('Clear All Data'), findsOneWidget);
  });
}
