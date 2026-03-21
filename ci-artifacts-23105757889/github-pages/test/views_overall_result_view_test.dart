import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';

void main() {
  testWidgets('OverallResultView renders title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MatchRepository()),
          ProxyProvider<MatchRepository, OverallResultViewModel>(
            update: (_, repo, __) => OverallResultViewModel(repo),
          ),
        ],
        child: const MaterialApp(home: OverallResultView()),
      ),
    );
    expect(find.text('Overall Result'), findsOneWidget);
  });
}
