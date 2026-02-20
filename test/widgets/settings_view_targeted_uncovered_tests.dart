import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

/// Deterministic tests targeting uncovered export/import branches.
class _FakeFileObj {
  final String path;
  _FakeFileObj(this.path);
}

class ThrowingPersistence extends FakePersistence {
  ThrowingPersistence() : super(exportJsonValue: '{}');
  @override
  Future<File> exportBackupToFile(String path) async {
    throw Exception('disk error');
  }
}

void main() {
  testWidgets('Export fallback shows Export failed when persistence throws', (tester) async {
    final repo = MatchRepository(persistence: ThrowingPersistence());
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(documentsDirOverride: () async => _FakeFileObj('/tmp')),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    // exportBackupForTest is a test-only wrapper on the state that performs the
    // export flow deterministically; call it to exercise the export error branch.
    await (state as dynamic).exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('Import from documents: dry-run validation failure shows SnackBar', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad backup');
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<List<dynamic>> listBackups() async => [ _FakeFileObj('/tmp/foo_backup.json') ];
    Future<Uint8List> readBytes(String path) async => Uint8List.fromList('{}'.codeUnits);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(listBackupsOverride: listBackups, readFileBytesOverride: readBytes),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('foo_backup.json'), findsOneWidget);
    await tester.tap(find.text('foo_backup.json'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Backup validation failed'), findsOneWidget);
  });
}
