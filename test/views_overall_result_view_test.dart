import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/overall_result_view.dart';

void main() {
  testWidgets('OverallResultView renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OverallResultView()));
    expect(find.text('Overall Result'), findsOneWidget);
  });
}
