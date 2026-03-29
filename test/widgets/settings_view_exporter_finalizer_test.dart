import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exporter finalizer timeout is handled and export completes', (WidgetTester tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    final tmp = Directory.systemTemp.createTempSync();

    // Ensure snackbars are suppressed so tests don't wait on timers
    final prevSuppress = SettingsView.suppressSnackBarsInTests;
    SettingsView.suppressSnackBarsInTests = true;

    // Provide a postExportOverride that sleeps longer than the internal
    // exporter timeout (2s) so the TimeoutException path is exercised.
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            documentsDirOverride: () async => tmp,
            postExportOverride: (String p, String c) async {
              await Future<void>.delayed(const Duration(seconds: 3));
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call the IO export path which will write a file then call our slow
    // postExportOverride; the internal timeout will fire and be caught.
    await state.exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // The method should still complete and set a status mentioning 'Exported'
    expect(find.textContaining('Exported to'), findsOneWidget);

    SettingsView.suppressSnackBarsInTests = prevSuppress;
  });
}
