import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/views/adjust_scaling_view.dart';

void main() {
  testWidgets('AdjustScalingView shows shooters and defaults, button enables when all entered and updates scaling',
      (WidgetTester tester) async {
    // Prepare in-memory prefs with two shooters missing classificationScore (simulate prior schema)
    final shooters = [
      {'name': 'Alice', 'scaleFactor': 1.0},
      {'name': 'Bob', 'scaleFactor': 1.0},
    ];
    SharedPreferences.setMockInitialValues({
      'shooters': jsonEncode(shooters),
      // ensure older schema version to exercise migration path
      kDataSchemaVersionKey: 0,
    });

    final prefs = await SharedPreferences.getInstance();
    // Ensure a clean prefs state even if another test initialized SharedPreferences
    await prefs.clear();
    // Persist the shooters we want for this test
    await prefs.setString('shooters', jsonEncode(shooters));
    await prefs.setInt(kDataSchemaVersionKey, 0);
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Build the widget
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: AdjustScalingView()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Expect two shooter rows
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    // Default controllers should show 100.0 after migration
    expect(find.textContaining('100.0'), findsNWidgets(2));

    // Button should be enabled because defaults are present
    final alignButton = find.text('Align scaling to CS');
    expect(alignButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);

    // Enter values: Alice 50, Bob 100 -> minCS = 50 -> newScale: Alice 50/50=1.0, Bob 50/100=0.5
    final aliceField = find.widgetWithText(TextField, 'Classification %').first;
    // There are two TextFields; enter Alice then Bob by index
    await tester.enterText(aliceField, '50');
    await tester.pump(const Duration(milliseconds: 200));

    // Enter Bob's field (second TextField)
    final bobField = find.widgetWithText(TextField, 'Classification %').at(1);
    await tester.enterText(bobField, '100');
    await tester.pump(const Duration(milliseconds: 200));

    // Press the button
    await tester.tap(alignButton);
    await tester.pump(const Duration(milliseconds: 200));

    // After alignment, repo should have updated scaleFactors
    final a = repo.getShooter('Alice');
    final b = repo.getShooter('Bob');
    expect(a, isNotNull);
    expect(b, isNotNull);
    // Alice CS=50, Bob CS=100, min=50 -> Alice scale = 50/50 = 1.0, Bob scale = 50/100 = 0.5
    expect(a!.scaleFactor, closeTo(1.0, 1e-6));
    expect(b!.scaleFactor, closeTo(0.5, 1e-6));
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Button disabled when any classification field invalid or empty', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'shooters': jsonEncode([
        {'name': 'X', 'scaleFactor': 1.0, 'classificationScore': 100.0},
        {'name': 'Y', 'scaleFactor': 1.0, 'classificationScore': 100.0},
      ]),
      kDataSchemaVersionKey: kDataSchemaVersion,
    });

    final prefs = await SharedPreferences.getInstance();
    // Ensure a clean prefs state even if another test initialized SharedPreferences
    await prefs.clear();
    // Persist the shooters we want for this test
    await prefs.setString('shooters', jsonEncode([
      {'name': 'X', 'scaleFactor': 1.0, 'classificationScore': 100.0},
      {'name': 'Y', 'scaleFactor': 1.0, 'classificationScore': 100.0},
    ]));
    await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: AdjustScalingView()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Clear one field to simulate missing value
    final firstField = find.widgetWithText(TextField, 'Classification %').first;
    await tester.enterText(firstField, '');
    await tester.pump(const Duration(milliseconds: 200));

    final button = find.widgetWithText(ElevatedButton, 'Align scaling to CS');
    expect(button, findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).enabled, isFalse);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
