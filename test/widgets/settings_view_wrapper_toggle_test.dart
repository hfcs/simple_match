import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('toggle suppressSnackBarsInTests and call wrappers', (tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    Future<void> exporter(String p, String c) async {
      // small noop exporter
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          pickBackupOverride: () async => null,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final st = tester.state(find.byType(SettingsView));
    final elem = tester.element(find.byType(SettingsView));

    // Call wrappers while suppressing snackbars
    final prior = SettingsView.suppressSnackBarsInTests;
    SettingsView.suppressSnackBarsInTests = true;
    try {
      await (st as dynamic).exportViaWebForTest(elem, repo.persistence ?? FakePersistence(), exporter, DateTime.now().toIso8601String());
      await (st as dynamic).exportBackupForTest(elem);
    } finally {
      SettingsView.suppressSnackBarsInTests = prior;
    }

    // Call wrappers without suppressing snackbars (different return paths)
    SettingsView.suppressSnackBarsInTests = false;
    try {
      await (st as dynamic).exportViaWebForTest(elem, repo.persistence ?? FakePersistence(), exporter, DateTime.now().toIso8601String());
      await (st as dynamic).exportBackupForTest(elem);
    } finally {
      SettingsView.suppressSnackBarsInTests = prior;
    }
  });
}
