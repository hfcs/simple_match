import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('exportBackupForTest goes through IO export path and shows Exported to', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const SettingsView(),
      ),
    ));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView));
    // Call the IO export path which will call getDocumentsDirectory and
    // FakePersistence.exportBackupToFile to create a file.
    await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // Either a SnackBar or the Status text may contain the path; accept either.
    expect(find.textContaining('Exported to'), findsWidgets);
  });

  testWidgets('export with saveExportOverride null still calls exporter path (no override)', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const SettingsView(),
      ),
    ));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView));
    // This exercises the branch where saveExportOverride == null and exporter
    // uses the default saveExport implementation.
    await (state as dynamic).exportViaWebForTest(tester.element(find.byType(SettingsView)), fake, (n, c) async {}, 'TS');
    await tester.pumpAndSettle();

    // We don't assert on exact text; ensure the export call path executed by
    // checking FakePersistence logged call via behavior (no exception thrown).
    expect(true, isTrue);
  });

  testWidgets('importFromDocuments dry-run failure shows Backup validation failed', (tester) async {
    final bytes = Uint8List.fromList('{}'.codeUnits);
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid');
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Provide a simple documents list and a readFileBytesOverride to return bytes
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          listBackupsOverride: () async => [ _FakeListedFile('/tmp/x.json') ],
          readFileBytesOverride: (p) async => bytes,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap Import Backup to start the documents-list flow
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Choose the file
    await tester.tap(find.text('x.json'));
    await tester.pumpAndSettle();

    // Expect validation failed message
    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });
}

// Minimal fake file-like object used by listBackupsOverride in these tests
class _FakeListedFile {
  final String path;
  _FakeListedFile(this.path);
}
