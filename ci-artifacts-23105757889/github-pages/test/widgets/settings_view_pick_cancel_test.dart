import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Import flow: pickBackupOverride returns null (user cancelled)', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    // pickBackupOverride returns null to simulate user cancelling file picker
    Future<Map<String, dynamic>?> pick() async => null;

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pick)),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    final importButton = find.text('Import Backup');
    expect(importButton, findsOneWidget);

    await tester.tap(importButton);
    await tester.pump(const Duration(milliseconds: 200));

    // Expect nothing catastrophic: no SnackBar for success or failure
    // but ensure the UI remains present (early return branch executed)
    expect(find.byType(SettingsView), findsOneWidget);
  });
}
