import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/stage_input_view.dart';

void main() {
  testWidgets('StageInputView renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StageInputView()));
    expect(find.text('Stage Input'), findsOneWidget);
  });
}
