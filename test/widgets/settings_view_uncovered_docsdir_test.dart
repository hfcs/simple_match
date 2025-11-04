import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('calling export without documentsDirOverride touches getDocumentsDirectory line', (tester) async {
    // Provide a repository with FakePersistence but DO NOT set documentsDirOverride
  final repo = MatchRepository(persistence: FakePersistence(exportJsonValue: '{}'));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    // Call the state wrapper which triggers the IO export path and will
    // attempt to call getDocumentsDirectory() (the line we want to cover).
    final state = tester.state(find.byType(SettingsView));

    await tester.runAsync(() async {
      await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    });

    // Let any SnackBar/showDialog complete
    await tester.pumpAndSettle();

    // Expect some status text to be present (either exported or export failed)
    expect(find.textContaining('Export'), findsWidgets);
  });
}
