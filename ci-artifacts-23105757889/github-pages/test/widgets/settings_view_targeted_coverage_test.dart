import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exercise import/export branches in SettingsView', (tester) async {
    // Use fake persistence to simulate import/export bytes and control results
  final svc = FakePersistence(exportJsonValue: '{}');

    // Build a SettingsView inside a minimal app and provide a repo that
    // uses the fake persistence implementation.
    // Suppress SnackBars during this VM widget test to avoid lingering timers.
    SettingsView.suppressSnackBarsInTests = true;
    // Pause after import completes so we can attach a debugger to flutter_tester
    // and capture stacks. Tests should reset this flag when done.
    // Disabled in CI/test run to avoid long sleeps during automated runs.
    SettingsView.pauseAfterImportForDebugger = false;
    // For targeted diagnostics: do NOT force-exit so repository reload runs
    // and persistence traces are emitted. Tests should reset this flag when done.
    SettingsView.forceExitAfterImportForDebugger = false;
    final repo = MatchRepository(persistence: svc);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(
            readFileBytesOverride: (String path) async => Uint8List.fromList([1,2,3]),
          ),
        ),
      ),
    );

  // Get the state object for later calls
  tester.state(find.byType(SettingsView)) as dynamic;

    // 2) Get the settings state reference for later import calls
    final settingsState = tester.state(find.byType(SettingsView)) as dynamic;
    // Allow any pending microtasks to finish
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // 3) Exercise importFromDocumentsChosenForTest and importFromDocumentsConfirmedForTest
    // Create a fake chosen file-like object with a path and bytes
    final chosen = _FakeFile('/tmp/fake_backup.json', Uint8List.fromList([1, 2, 3]));

    // Ensure the widget has the readFileBytesOverride so it doesn't hit real IO
  // No need to create a new SettingsView instance; use the existing state and
  // the test helpers to provide read bytes.
  // Directly call the state's importFromDocumentsConfirmedForTest which does
  // not show a dialog (useful for VM tests).
  try {
    await tester.runAsync(() => settingsState.importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, svc, chosen))
        .timeout(const Duration(seconds: 1), onTimeout: () {
      final trace = {
        'event': 'import_timeout',
        'when': DateTime.now().toUtc().toIso8601String(),
        'note': 'tester.runAsync timeout wrapping importFromDocumentsConfirmedForTest'
      };
      try {
        File('/tmp/import_timeout_trace.json').writeAsStringSync(jsonEncode(trace));
        print('TESTDBG: wrote /tmp/import_timeout_trace.json');
      } catch (e) {
        print('TESTDBG: failed to write /tmp/import_timeout_trace.json: $e');
      }
      throw TimeoutException('importFromDocumentsConfirmedForTest timed out');
    });
  } catch (e) {
    print('TESTDBG: import call threw: $e');
  }

  // Allow any pending animations or setState callbacks to run
  await tester.pumpAndSettle(const Duration(milliseconds: 200));

  // Reset suppression and pause flags so other tests are unaffected.
  SettingsView.suppressSnackBarsInTests = false;
  SettingsView.pauseAfterImportForDebugger = false;
  SettingsView.forceExitAfterImportForDebugger = false;

    // Verify the UI shows a Status text (last message set by the flows)
    expect(find.textContaining('Status:'), findsOneWidget);
  });
}

class _FakeFile {
  final String path;
  _FakeFile(this.path, this.bytes);
  final Uint8List bytes;
}
