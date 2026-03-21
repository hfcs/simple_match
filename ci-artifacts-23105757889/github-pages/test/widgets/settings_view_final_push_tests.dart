import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw StateError('loadAll failed');
  }
}

class _FakeListedFile {
  final String path;
  _FakeListedFile(this.path);
}

void main() {
  testWidgets('export shows Export failed when exporter throws', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{}');

    Future<Never> exporter(String path, String content) async {
      throw Exception('boom');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: MatchRepository(persistence: fake),
        child: SettingsView(saveExportOverride: exporter),
      ),
    ));

    // Call export via state wrapper to avoid tap hit-test issues
    final state = tester.state(find.byType(SettingsView));
    await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pump(const Duration(milliseconds: 200));

    // Both the SnackBar and the Status text may contain the message; accept both.
    expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('import with pickBackupOverride: reload failure branch handled', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{}', importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    Future<Map<String, Object>> pick() async => {'bytes': Uint8List.fromList([1, 2, 3]), 'name': 'ok.json', 'autoConfirm': true};

    final throwingRepo = _ThrowingRepo(persistence: fake);
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: throwingRepo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

  // Trigger the Import Backup button (this calls the internal import flow)
  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The page should show the import succeeded but reload failed message
    expect(find.textContaining('Import succeeded, reload failed'), findsOneWidget);
  });

  testWidgets('import from documents: reload failure branch handled', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{}', importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    Future<List<dynamic>> listBackups() async => [ _FakeListedFile('/tmp/x.json') ];

    Future<Uint8List> readBytes(String path) async => Uint8List.fromList([4,5,6]);

    final throwingRepo2 = _ThrowingRepo(persistence: fake);
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: throwingRepo2,
        child: SettingsView(listBackupsOverride: listBackups, readFileBytesOverride: readBytes),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

  // Trigger Import Backup button which opens the documents selection dialog
  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Select the listed backup (text is the filename 'x.json')
    expect(find.text('x.json'), findsOneWidget);
    await tester.tap(find.text('x.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // Confirm the restore in the AlertDialog by tapping 'Restore'
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import succeeded, reload failed'), findsOneWidget);
  });
}
