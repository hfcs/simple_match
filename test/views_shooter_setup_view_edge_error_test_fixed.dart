import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/shooter_setup_view.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _MockPersistenceService extends PersistenceService {}

void main() {
  group('ShooterSetupView edge/error coverage (fixed file)', () {
    testWidgets('Add, edit, cancel, remove, and error flows', (tester) async {
      final repo = MatchRepository(persistence: _MockPersistenceService());
      final vm = ShooterSetupViewModel(repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => repo),
            Provider(create: (_) => vm),
          ],
          child: const MaterialApp(home: ShooterSetupView()),
        ),
      );
      // Add a shooter
      await tester.enterText(find.byKey(const Key('nameField')), 'Alice');
      await tester.enterText(find.byKey(const Key('scaleField')), '1.0');
      await tester.tap(find.byKey(const Key('addShooterButton')));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
      // Edit the shooter
      await tester.tap(find.byKey(const Key('editShooter-Alice')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('scaleField')), '1.5');
      await tester.tap(find.byKey(const Key('confirmEditButton')));
      await tester.pumpAndSettle();
      expect(find.text('1.500', skipOffstage: false), findsWidgets);
      // Enter edit mode and cancel
      await tester.tap(find.byKey(const Key('editShooter-Alice')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addShooterButton')), findsOneWidget);
      // Remove the shooter (confirm dialog)
      await tester.tap(find.byKey(const Key('removeShooter-Alice')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsNothing);
      // Add invalid input to trigger error
      await tester.enterText(find.byKey(const Key('nameField')), '');
      await tester.enterText(find.byKey(const Key('scaleField')), '');
      await tester.tap(find.byKey(const Key('addShooterButton')));
      await tester.pumpAndSettle();
      expect(find.text('Invalid scale.'), findsOneWidget);
    });
  });
}
