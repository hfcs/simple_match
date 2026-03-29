import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('pick backup dry-run validation failure shows status', (WidgetTester tester) async {
    // Arrange: persistence that fails validation on dry-run
    final fakeFail = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid');
      return FakeImportResult(success: false, message: 'invalid');
    });
    final repo = MatchRepository(persistence: fakeFail);

    final tmp = Directory.systemTemp.createTempSync();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': Uint8List.fromList([9,9,9]), 'name': 'bad.json', 'autoConfirm': true},
            documentsDirOverride: () async => tmp,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Act: call the export/import path that uses pickBackupOverride
    await state.exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // Assert: status text shows validation failure in the Status line
    expect(find.text('Status: Backup validation failed: invalid'), findsOneWidget);
  });
}
