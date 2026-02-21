import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
// optional import removed: don't import package:simple_match/main.dart in tests
import 'package:simple_match/views/main_menu_view.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('App main smoke: can render MainMenuView inside app', (tester) async {
    final repo = MatchRepository();
    await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(value: repo, child: const MainMenuView())));
    await tester.pumpAndSettle();
    expect(find.text('Mini IPSC Match'), findsOneWidget);
  });
}
