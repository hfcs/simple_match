import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/shooter_setup_view.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  @override
  Future<List<Shooter>> loadShooters() async => [
    Shooter(name: 'Test', scaleFactor: 1.0),
  ];
}

void main() {
  group('ShooterSetupView uncovered branches', () {
    testWidgets('shows error for duplicate shooter name', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        persistence: MockPersistenceService(),
        initialStages: [],
        initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
      );
      final vm = ShooterSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            Provider<ShooterSetupViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: ShooterSetupView()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      // Try to add duplicate shooter
      await tester.enterText(find.byKey(const Key('nameField')), 'Test');
      await tester.enterText(find.byKey(const Key('scaleField')), '1.0');
      await tester.tap(find.byKey(const Key('addShooterButton')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Shooter already exists.'), findsOneWidget);
    });

    testWidgets('shows error for invalid scale factor', (
      WidgetTester tester,
    ) async {
      final repo = MatchRepository(
        persistence: MockPersistenceService(),
        initialStages: [],
        initialShooters: [],
      );
      final vm = ShooterSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            Provider<ShooterSetupViewModel>.value(value: vm),
          ],
          child: MaterialApp(home: ShooterSetupView()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      // Enter invalid scale factor
      await tester.enterText(find.byKey(const Key('nameField')), 'NewShooter');
      await tester.enterText(find.byKey(const Key('scaleField')), 'abc');
      await tester.tap(find.byKey(const Key('addShooterButton')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Invalid scale.'), findsOneWidget);
    });
    testWidgets('shows error on invalid scale and empty state', (tester) async {
      final repo = MatchRepository(persistence: PersistenceService());
      await tester.pumpWidget(
        Provider<ShooterSetupViewModel>(
          create: (_) => ShooterSetupViewModel(repo),
          child: const MaterialApp(home: ShooterSetupView()),
        ),
      );
      // Try to add with missing scale
      await tester.enterText(find.byKey(const Key('nameField')), 'Test');
      await tester.enterText(find.byKey(const Key('scaleField')), '');
      await tester.tap(find.byKey(const Key('addShooterButton')));
      await tester.pump();
      expect(find.textContaining('Invalid'), findsOneWidget);
      // Should show empty state (no shooters)
      expect(find.text('Shooters:'), findsOneWidget);
    });
  });
}
