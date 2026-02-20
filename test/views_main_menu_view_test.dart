import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/main_menu_view.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('MainMenuView renders all buttons', (WidgetTester tester) async {
    final repo = MatchRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: const MainMenuView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Match Setup'), findsOneWidget);
    expect(find.text('Shooter Setup'), findsOneWidget);
    expect(find.text('Stage Input'), findsOneWidget);
  });
}
