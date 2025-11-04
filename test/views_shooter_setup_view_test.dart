import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/shooter_setup_view.dart';

import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';

Widget _wrapWithProviders(Widget child) {
  return ChangeNotifierProvider<MatchRepository>(
    create: (_) => MatchRepository(),
    child: Provider<ShooterSetupViewModel>(
      create: (context) => ShooterSetupViewModel(
        Provider.of<MatchRepository>(context, listen: false),
      ),
      child: MaterialApp(home: child),
    ),
  );
}

void main() {
  testWidgets('ShooterSetupView renders title', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ShooterSetupView()));
    expect(find.text('Shooter Setup'), findsOneWidget);
  });

  testWidgets('Can add a shooter', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ShooterSetupView()));
    await tester.enterText(find.byKey(const Key('nameField')), 'Alice');
    await tester.enterText(find.byKey(const Key('scaleField')), '0.95');
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byKey(const Key('scaleValue-Alice')), findsOneWidget);
  });

  testWidgets('Cannot add duplicate shooter', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ShooterSetupView()));
    await tester.enterText(find.byKey(const Key('nameField')), 'Bob');
    await tester.enterText(find.byKey(const Key('scaleField')), '1.0');
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('nameField')), 'Bob');
    await tester.enterText(find.byKey(const Key('scaleField')), '0.9');
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    expect(find.textContaining('already exists'), findsOneWidget);
  });

  testWidgets('Can edit shooter scale', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ShooterSetupView()));
    await tester.enterText(find.byKey(const Key('nameField')), 'Charlie');
    await tester.enterText(find.byKey(const Key('scaleField')), '1.0');
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('editShooter-Charlie')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('scaleField')), '0.8');
    await tester.tap(find.byKey(const Key('confirmEditButton')));
    await tester.pump();
    expect(find.byKey(const Key('scaleValue-Charlie')), findsOneWidget);
  });

  testWidgets('Can remove shooter', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ShooterSetupView()));
    await tester.enterText(find.byKey(const Key('nameField')), 'Dana');
    await tester.enterText(find.byKey(const Key('scaleField')), '0.7');
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('removeShooter-Dana')));
    await tester.pump();
    expect(find.text('Dana'), findsNothing);
  });

  testWidgets('Shows validation error for invalid scale', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ShooterSetupView()));
    await tester.enterText(find.byKey(const Key('nameField')), 'Eve');
    await tester.enterText(
      find.byKey(const Key('scaleField')),
      '0.05',
    ); // too low
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    expect(
      find.textContaining('Invalid scale: must be between 0.100 and 2.000.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('scaleField')),
      '2.5',
    ); // too high
    await tester.tap(find.byKey(const Key('addShooterButton')));
    await tester.pump();
    expect(
      find.textContaining('Invalid scale: must be between 0.100 and 2.000.'),
      findsOneWidget,
    );
  });
}
