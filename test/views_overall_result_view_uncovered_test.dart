import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/overall_result_view.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';

class MockRepo extends MatchRepository {
  MockRepo()
    : super(initialStages: [], initialShooters: [], initialResults: []);
}

void main() {
  testWidgets('OverallResultView edge case', (WidgetTester tester) async {
    final repo = MockRepo();
    final vm = OverallResultViewModel(repo);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MatchRepository>.value(value: repo),
          Provider<OverallResultViewModel>.value(value: vm),
        ],
        child: const MaterialApp(home: OverallResultView()),
      ),
    );
    // Should render without crashing even with no data
    expect(find.byType(OverallResultView), findsOneWidget);
    // Should show empty state message
    expect(find.text('No results yet.'), findsOneWidget);
  });
}
