import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Pressing Export Backup calls saveExportOverride', (tester) async {
    // Use fake persistence to avoid dart:io and platform plugins
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final completer = Completer<void>();
    var called = false;
    Future<void> fakeSaveExport(String path, String contents) async {
      called = true;
      if (!completer.isCompleted) completer.complete();
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: fakeSaveExport)),
      ),
    );

    await tester.pump();

    final exportButton = find.text('Export Backup');
    expect(exportButton, findsOneWidget);

    await tester.tap(exportButton);
    await tester.pump();

    // allow async operations to run
    // Wait for fakeSaveExport to be called, or timeout after 2s
    try {
      await completer.future.timeout(const Duration(seconds: 2));
    } catch (_) {}

    expect(called, isTrue, reason: 'saveExportOverride should be invoked when Export Backup is tapped');
    // No disk cleanup needed for the override-based test
  });
}
