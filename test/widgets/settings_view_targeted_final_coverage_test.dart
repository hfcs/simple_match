import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFileObj {
  final String path;
  _FakeFileObj(this.path);
}

class ThrowingRepo extends MatchRepository {
  ThrowingRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('reload failed');
  }
}

void main() {
  testWidgets('exportViaWebForTest: web export wrapper updates status using a dummy exporter', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const SettingsView(),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    // Provide a dummy exporter that does minimal work to avoid FS I/O
    Future<void> dummyExporter(String name, String content) async {
      // no-op
      return Future.value();
    }

    // Call the web-export wrapper directly with the dummy exporter.
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    await (state as dynamic).exportViaWebForTest(tester.element(find.byType(SettingsView)), fake, dummyExporter, ts);
    await tester.pumpAndSettle();

  // The SettingsView also shows the same message without the "Status: "
  // prefix; assert the persistent status text specifically to avoid
  // matching the duplicate plain message widget.
  expect(find.textContaining('Status: Exported to browser'), findsOneWidget);
  });

  // NOTE: explicit IO-path export via the default exporter touches file I/O
  // and can hang in some test environments. We exercise the web-export
  // internals above and rely on existing export IO tests elsewhere in the
  // suite that exercise saveExportOverride paths.

  testWidgets('importViaWebForTest: pickBackupOverride returning null shows no-file SnackBar', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: () async => null),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    await (state as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);
    await tester.pumpAndSettle();

    expect(find.text('No file selected'), findsOneWidget);
  });

  testWidgets('importFromDocumentsChosenForTest: dry-run failure shows validation message', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'validation failed');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: (p) async => Uint8List.fromList([1,2,3])),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    final chosen = _FakeFileObj('/tmp/dummy.json');

  // Use the "Confirmed" helper to avoid showing the confirmation dialog
  // in VM tests (which can hang). The Confirmed variant skips the dialog.
  await (state as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup validation failed'), findsOneWidget);
  });

  testWidgets('importFromDocumentsChosenForTest: import succeeds but repo.reload throws shows reload failed', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });
    final repo = ThrowingRepo(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: (p) async => Uint8List.fromList([1,2,3])),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    final chosen = _FakeFileObj('/tmp/ok.json');

    await (state as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pumpAndSettle();

    expect(find.textContaining('Import succeeded, reload failed'), findsOneWidget);
  });

  testWidgets('exportBackupForTest: documentsDirOverride throwing triggers Export failed', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async { throw Exception('no access'); }),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // Persistent status should reflect the export failure
    expect(find.textContaining('Status: Export failed'), findsOneWidget);
  });

  testWidgets('importFromDocumentsForTest: empty documents list shows no-backups SnackBar', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(listBackupsOverride: () async => []),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    await (state as dynamic).importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo, fake);
    await tester.pumpAndSettle();

    expect(find.text('No backup files found in app documents directory'), findsOneWidget);
  });

  testWidgets('importFromDocumentsChosenForTest: final import failure sets Import failed status', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: false, message: 'final fail');
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: (p) async => Uint8List.fromList([1,2,3])),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    final chosen = _FakeFileObj('/tmp/fail.json');

  // Use the Confirmed helper to avoid showing the confirmation dialog
  // in VM tests (which can hang). The Confirmed variant skips the dialog.
  await (state as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pumpAndSettle();

    expect(find.textContaining('Status: Import failed: final fail'), findsOneWidget);
  });
}
