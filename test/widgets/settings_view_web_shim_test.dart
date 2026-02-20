import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('shim: invoke _importViaWeb through state to exercise web branch', (tester) async {
    // Prepare a fake persistence that returns a successful dry-run/import
  final fake = FakePersistence(exportJsonValue: '{}');
  final repo = MatchRepository(persistence: fake);

    // Provide a pickBackupOverride that simulates a browser pick with autoConfirm=true
    Future<Map<String, Object>> pick() async => {
      'bytes': Uint8List.fromList([1, 2, 3]),
      'name': 'shim.json',
      'autoConfirm': true,
    };

    // Force the test flag in case code paths check it in future. This shim
    // will call the private helper directly via the state object.
    SettingsView.forceKIsWeb = true;

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));

  // Locate the state object for the SettingsView and call the test-only wrapper.
  final state = tester.state(find.byType(SettingsView));
  // Call the test-only wrapper added to _SettingsViewState.
  await (state as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);

    // Allow any SnackBars to appear
    await tester.pump(const Duration(milliseconds: 200));

    // Expect the status text to update to 'Import successful' (state sets _lastMessage)
    expect(find.textContaining('Import successful'), findsWidgets);

    SettingsView.forceKIsWeb = false;
  });
}
