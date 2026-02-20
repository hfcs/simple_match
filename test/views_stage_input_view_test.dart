import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/stage_input_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';

Widget _wrapWithProviders(Widget child, MatchRepository repo) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MatchRepository>.value(value: repo),
      ChangeNotifierProvider<StageInputViewModel>(
        create: (context) => StageInputViewModel(repo),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

// Wait until a finder resolves or timeout after several short pumps.
Future<void> _waitForFinder(WidgetTester tester, Finder finder, {int retries = 10}) async {
  for (var i = 0; i < retries; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pump();
}

// Guarded tap: wait for the finder, ensure it's visible, then tap and settle briefly.
Future<void> _guardedTap(WidgetTester tester, Finder finder, {int retries = 10}) async {
  await _waitForFinder(tester, finder, retries: retries);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('StageInputView', () {
    late MatchRepository repo;
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      repo = MatchRepository();
      repo.addShooter(Shooter(name: 'Alice', scaleFactor: 0.9));
      repo.addShooter(Shooter(name: 'Bob', scaleFactor: 1.0));
      repo.addStage(MatchStage(stage: 1, scoringShoots: 10));
      repo.addStage(MatchStage(stage: 2, scoringShoots: 8));
    });

    testWidgets(
      'renders all input fields and selectors in vertical layout with +/- buttons',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithProviders(const StageInputView(), repo),
        );
        expect(find.byKey(const Key('stageSelector')), findsOneWidget);
        expect(find.byKey(const Key('shooterSelector')), findsOneWidget);
        // Each field should have its own Row with - [TextField] +
        expect(find.byKey(const Key('timeField')), findsOneWidget);
        expect(find.byKey(const Key('aField')), findsOneWidget);
        expect(find.byKey(const Key('cField')), findsOneWidget);
        expect(find.byKey(const Key('dField')), findsOneWidget);
        expect(find.byKey(const Key('missesField')), findsOneWidget);
        expect(find.byKey(const Key('noShootsField')), findsOneWidget);
        expect(find.byKey(const Key('procErrorsField')), findsOneWidget);
        // There should be at least 7 increment and 7 decrement IconButtons (one for each field)
        final addButtons = find.widgetWithIcon(IconButton, Icons.add);
        final removeButtons = find.widgetWithIcon(IconButton, Icons.remove);
        expect(addButtons, findsNWidgets(7));
        expect(removeButtons, findsNWidgets(7));
        // Submit button is below all fields
        expect(find.byKey(const Key('submitButton')), findsOneWidget);
      },
    );

    testWidgets('disables submit if input is invalid', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter programmatically to avoid popup tap flakiness
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));
      // Enter invalid values
      await tester.enterText(find.byKey(const Key('aField')), '3');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '3');
      await tester.enterText(
        find.byKey(const Key('missesField')),
        '2',
      ); // 3+3+3+2=11 != 10
      await tester.pump();
      final submit = tester.widget<ElevatedButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(submit.enabled, isFalse);
      expect(find.textContaining('must equal'), findsOneWidget);
    });

    testWidgets('enables submit and displays hit factors when valid', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter programmatically to avoid popup tap flakiness
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));
      // Enter valid values
  await tester.ensureVisible(find.byKey(const Key('timeField')));
  await tester.enterText(find.byKey(const Key('timeField')), '10.0');
      await tester.enterText(find.byKey(const Key('aField')), '5');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.enterText(find.byKey(const Key('noShootsField')), '0');
      await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
      await tester.pump();
      final submit = tester.widget<ElevatedButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(submit.enabled, isTrue);
      expect(find.textContaining('Hit Factor'), findsOneWidget);
      expect(find.textContaining('Adjusted'), findsOneWidget);
    });

    testWidgets('submits and displays in result list', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter programmatically to avoid popup tap flakiness
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));
      // Enter valid values
  await tester.ensureVisible(find.byKey(const Key('timeField')));
  await tester.enterText(find.byKey(const Key('timeField')), '10.0');
      await tester.enterText(find.byKey(const Key('aField')), '5');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.enterText(find.byKey(const Key('noShootsField')), '0');
      await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
      await tester.pump();
      // Ensure submit button is visible before tapping
      await tester.ensureVisible(find.byKey(const Key('submitButton')));
      await _guardedTap(tester, find.byKey(const Key('submitButton')));
      await tester.pump();
      // Ensure results list is visible before checking
      await tester.ensureVisible(find.byKey(const Key('resultsList')));
      expect(find.text('Alice'), findsWidgets);
      expect(
        find.textContaining('Stage: 1'),
        findsWidgets,
      ); // Stage number in subtitle
      expect(
        find.textContaining('Time: 10.0'),
        findsWidgets,
      ); // Time in subtitle
    });

    testWidgets('DNF result displays status-only in result list', (tester) async {
  // Increase test environment size so radio tiles are visible and hittable
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and set shooter programmatically (avoid menu tap flakiness)
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Bob');
      await tester.pump(const Duration(milliseconds: 200));
  // Mark as DNF and set an RO remark
  await tester.ensureVisible(find.text('DNF'));
  await _guardedTap(tester, find.text('DNF').first);
  await tester.pump();
  await tester.enterText(find.byKey(const Key('roRemarkField')), 'Gun jam');
  await tester.pump();
  // Submit (vm.submit() will zero numeric fields for non-completed statuses)
  await _guardedTap(tester, find.byKey(const Key('submitButton')));
  await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('resultsList')));
  // The result subtitle should contain 'Status: DNF' and the RO remark, but not the time or numeric labels
  expect(find.textContaining('Status: DNF'), findsWidgets);
  expect(find.textContaining('RO: Gun jam'), findsWidgets);
  expect(find.textContaining('Time:'), findsNothing);
  expect(find.textContaining('A:'), findsNothing);
      // Reset test environment size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('can edit and remove a result', (tester) async {
  // Increase test environment size to avoid off-screen widget issues
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Add a result via ViewModel to avoid menu tap flakiness
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));
  await tester.ensureVisible(find.byKey(const Key('timeField')));
  await tester.enterText(find.byKey(const Key('timeField')), '10.0');
      await tester.enterText(find.byKey(const Key('aField')), '5');
      await tester.enterText(find.byKey(const Key('cField')), '3');
      await tester.enterText(find.byKey(const Key('dField')), '2');
      await tester.enterText(find.byKey(const Key('missesField')), '0');
      await tester.enterText(find.byKey(const Key('noShootsField')), '0');
      await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
      await tester.pump();
      await _guardedTap(tester, find.byKey(const Key('submitButton')));
      await tester.pump();
      // Ensure results list is visible
      await tester.ensureVisible(find.byKey(const Key('resultsList')));
      // Tap edit
      await tester.ensureVisible(find.byKey(const Key('editResult-1-Alice')));
      await _guardedTap(tester, find.byKey(const Key('editResult-1-Alice')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('aField')), '4');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('submitButton')));
      await _guardedTap(tester, find.byKey(const Key('submitButton')));
      await tester.pump();
      expect(find.text('4'), findsWidgets);
      // Tap remove
      await tester.ensureVisible(find.byKey(const Key('removeResult-1-Alice')));
      await _guardedTap(tester, find.byKey(const Key('removeResult-1-Alice')));
      await tester.pump(const Duration(milliseconds: 200));
      // Confirm removal from dialog
      await _guardedTap(tester, find.text('Remove'));
      await tester.pump(const Duration(milliseconds: 200));
      // Only check that Alice is not present in the results list (no ListTile with her name)
      final resultTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(
        resultTiles.where((tile) => (tile.title as Text).data == 'Alice'),
        isEmpty,
      );
      // Reset test environment size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('DQ-ed shooters are greyed out and unselectable in shooter selector', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
  // Pre-populate a DQ result for Bob
  repo.addResult(StageResult(stage: 1, shooter: 'Bob', status: 'DQ'));
      // Rebuild UI
      await tester.pump(const Duration(milliseconds: 200));
      // Open shooter selector
      await _guardedTap(tester, find.byKey(const Key('shooterSelector')));
      await tester.pump(const Duration(milliseconds: 200));
      // The menu should show Bob annotated and greyed out
      expect(find.text("Bob (DQ'ed)"), findsOneWidget);
      final bobText = tester.widget<Text>(find.text("Bob (DQ'ed)").first);
      expect(bobText.style?.color, equals(Colors.grey));
      // Try to tap Bob - since the menu item is disabled, tapping it should not select Bob
      await _guardedTap(tester, find.text("Bob (DQ'ed)").first);
      await tester.pump(const Duration(milliseconds: 200));
      // Selected shooter should still be null / not Bob
      expect(find.textContaining('Bob'), findsWidgets); // appears in menu, but not selected label
      expect(find.text('Select Shooter'), findsOneWidget);
    });

    testWidgets('DQ requires non-empty RO remark and disables submit when blank', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter programmatically to avoid popup tap flakiness
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));
      // Select DQ status
      await tester.ensureVisible(find.text('DQ'));
      await _guardedTap(tester, find.text('DQ').first);
      await tester.pump();
      // Clear RO remark if any and ensure it's empty/whitespace
      await tester.enterText(find.byKey(const Key('roRemarkField')), '   ');
      await tester.pump();
      // Submit should be disabled and validation should show
      final submitBtn = tester.widget<ElevatedButton>(find.byKey(const Key('submitButton')));
      expect(submitBtn.enabled, isFalse);
      expect(find.textContaining("RO remark is required for DQ"), findsOneWidget);
    });

    testWidgets('DQ with RO remark allows submit', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const StageInputView(), repo));
      // Select stage and shooter programmatically to avoid popup tap flakiness
      final vm = Provider.of<StageInputViewModel>(
        tester.element(find.byType(StageInputView)),
        listen: false,
      );
      vm.selectStage(1);
      vm.selectShooter('Alice');
      await tester.pump(const Duration(milliseconds: 200));
      // Select DQ status
      await tester.ensureVisible(find.text('DQ'));
      await _guardedTap(tester, find.text('DQ').first);
      await tester.pump();
      // Provide RO remark
      await tester.enterText(find.byKey(const Key('roRemarkField')), 'RO observed illegal procedure');
      await tester.pump();
      // Submit should be enabled
      final submitBtn = tester.widget<ElevatedButton>(find.byKey(const Key('submitButton')));
      expect(submitBtn.enabled, isTrue);
    });
  });
}
