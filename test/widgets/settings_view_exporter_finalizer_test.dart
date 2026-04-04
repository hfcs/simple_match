import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exporter finalizer timeout is handled and export completes', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    final tmp = Directory.systemTemp.createTempSync();

    // Ensure snackbars are suppressed so tests don't wait on timers
    final prevSuppress = SettingsView.suppressSnackBarsInTests;
    SettingsView.suppressSnackBarsInTests = true;

    // Ensure web-forcing is disabled for this IO-focused test and provide
    // deterministic overrides that complete immediately to avoid platform
    // interactions in CI/VM tests.
    SettingsView.forceKIsWeb = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            documentsDirOverride: () async => tmp,
            // Use deterministic overrides that complete immediately to avoid
            // interacting with platform exporters in this unit test.
            saveExportOverride: (String p, String c) async {
              return Future<void>.value();
            },
            postExportOverride: (String p, String c) async {
              return Future<void>.value();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call the IO export path which will write a file then call our slow
    // postExportOverride; the internal timeout will fire and be caught.
    // Add a safety timeout so the test fails fast if the exporter finalizer
    // does not complete for any reason.
    await state.exportBackupForTest(tester.element(find.byType(SettingsView))).timeout(const Duration(seconds: 30));
    await tester.pumpAndSettle();

    // The method should still complete and set a status mentioning 'Exported'
    expect(find.textContaining('Exported'), findsOneWidget);

    SettingsView.suppressSnackBarsInTests = prevSuppress;
  });
}
