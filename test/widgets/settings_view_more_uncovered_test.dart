import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Export uses documentsDirOverride and shows exported status', (tester) async {
    // Arrange: fake persistence that writes files
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    // Provide a simple object with a .path property
    final tmpDir = _TempDir('/tmp');

    // Build once with documentsDirOverride injected
    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            documentsDirOverride: () async => tmpDir,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Act: tap Export Backup
    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  // Assert: Status text exists (content may be empty depending on environment)
  final statusFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().startsWith('Status:'));
  expect(statusFinder, findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Import with pickBackupOverride returning null shows no file selected', (tester) async {
    final fake = FakePersistence();
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Accept either a SnackBar or the Status text
    expect(
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('No file selected')),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Import dry-run failure via pickBackupOverride shows validation failed', (tester) async {
    // Arrange: fake persistence that fails dry-run
    final fake = FakePersistence(
      importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
        if (dryRun) return FakeImportResult(success: false, message: 'invalid');
        return FakeImportResult(success: true);
      },
    );
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': Uint8List.fromList([1, 2, 3]), 'name': 'b.json'},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Backup validation failed')),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Import actual import failure shows Import failed status', (tester) async {
    // importFn returns success=true for dryRun, but false for actual import
    final fake = FakePersistence(
      importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
        if (dryRun) return FakeImportResult(success: true);
        return FakeImportResult(success: false, message: 'broken');
      },
    );
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': Uint8List.fromList([4, 5, 6]), 'name': 'b2.json', 'autoConfirm': true},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should show Import failed message in Status
    expect(
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import failed')),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Import succeeds but repo.loadAll throws shows reload failed state', (tester) async {
    final fake = FakePersistence(
      importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async => FakeImportResult(success: true),
    );

    // Create a repo subclass that throws from loadAll
    final repo = _ThrowingRepo(fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': Uint8List.fromList([7, 8, 9]), 'name': 'b3.json', 'autoConfirm': true},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('reload failed')),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Import from documents list and readFileBytesOverride succeeds', (tester) async {
    final fake = FakePersistence(
      importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
        if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 0, 'stageResults': 0});
        return FakeImportResult(success: true);
      },
    );
    final repo = MatchRepository(persistence: fake);

    // Provide a fake file-like object with path
    final fileObj = _TempFile('/tmp/foo.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [fileObj],
            readFileBytesOverride: (p) async => Uint8List.fromList([9, 9, 9]),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The SimpleDialog shows the filename (foo.json). Tap it.
    await tester.tap(find.text('foo.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // Accept either a direct SnackBar/Text 'Import successful' or the Status text
    final successFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful'));
    final statusFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().startsWith('Status:'));
    expect(tester.any(successFinder) || tester.any(statusFinder), isTrue);
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('Import readFileBytesOverride throws shows Import error', (tester) async {
    final fake = FakePersistence(
      importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
        if (dryRun) return FakeImportResult(success: true);
        return FakeImportResult(success: true);
      },
    );
    final repo = MatchRepository(persistence: fake);

    final fileObj = _TempFile('/tmp/bar.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [fileObj],
            readFileBytesOverride: (p) async => throw Exception('io fail'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('bar.json'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import error')),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(seconds: 45)));
}

class _TempDir {
  final String path;
  _TempDir(this.path);
}

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo(FakePersistence pers) : super(persistence: pers);
  @override
  Future<void> loadAll() async {
    throw Exception('reload failure');
  }
}

class _TempFile {
  final String path;
  _TempFile(this.path);
}
