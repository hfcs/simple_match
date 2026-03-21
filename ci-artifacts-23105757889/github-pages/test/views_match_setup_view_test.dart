import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:simple_match/views/match_setup_view.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('MatchSetupView renders title', (WidgetTester tester) async {
    // Provide a dummy MatchSetupViewModel for the test
    final vm = MatchSetupViewModel(MatchRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchRepository>.value(value: MatchRepository()),
            Provider<MatchSetupViewModel>.value(value: vm),
          ],
          child: const MatchSetupView(),
        ),
      ),
    );
    expect(find.text('Match Setup'), findsOneWidget);
  });
}
