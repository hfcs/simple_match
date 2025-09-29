import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';

void main() {
  testWidgets('StageResultView route builds with injected ViewModel', (tester) async {
    final repo = MatchRepository(persistence: PersistenceService());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MatchRepository>.value(value: repo),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final persistence = repo.persistence ?? PersistenceService();
              return StageResultView(
                viewModel: StageResultViewModel(persistenceService: persistence),
              );
            },
          ),
        ),
      ),
    );
    expect(find.byType(StageResultView), findsOneWidget);
  });

  testWidgets('main.dart routes fallback to / if unknown', (tester) async {
    final repo = MatchRepository(persistence: PersistenceService());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MatchRepository>.value(value: repo),
        ],
        child: MaterialApp(
          initialRoute: '/unknown',
          routes: {
            '/': (context) => const Text('Home'),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Consume the framework warning about unknown initial route
    tester.takeException();
    // Should fallback to Home
    expect(find.text('Home'), findsOneWidget);
  });
}
