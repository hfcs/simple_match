// Integration test for web-specific export/import flows.
// Run with: flutter test --platform chrome integration_test/settings_view_web_integration_test.dart

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Web export triggers browser download (kIsWeb)', (tester) async {
    // This test should be executed on the web platform (Chrome).
    // It exercises the kIsWeb branch in SettingsView._exportBackup.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(),
      ),
    ));

    // Tap export. On web this should call the web exporter which triggers
    // a browser download. We can't easily assert the download, but we can
    // assert the UI does not crash and shows a status update.
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Exported'), findsWidgets);
  });
}
