import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo(dynamic svc) : super(persistence: svc);
  @override
  Future<void> loadAll() async {
    throw Exception('reload failed');
  }
}

class _SpyRepo extends MatchRepository {
  final void Function() onLoad;
  _SpyRepo({super.persistence, required this.onLoad});
  @override
  Future<void> loadAll() async {
    onLoad();
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Import dry-run with invalid JSON shows error message',
      (WidgetTester tester) async {
    // Use FakePersistence that fails the dry-run validation for invalid bytes
    final repo = MatchRepository(
        persistence: FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid json', counts: {});
      return FakeImportResult(success: true, message: 'ok', counts: {});
    }));

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {
            'bytes': Uint8List.fromList('not-json'.codeUnits),
            'name': 'bad.json',
            'autoConfirm': true
          }
        ),
      ),
    ));

    // Tap import
    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  // Since import dry-run fails validation, expect a validation failure SnackBar
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('pickBackupOverride autoConfirm=false shows confirm dialog',
      (WidgetTester tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {
            'bytes': Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits),
            'name': 'ok.json',
            'autoConfirm': false
          }
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  // Should see a confirmation dialog
  expect(find.text('Confirm restore'), findsOneWidget);

  // Cancel the dialog
  await tester.tap(find.text('Cancel'));
  await tester.pump(const Duration(milliseconds: 200));

  // After cancelling, the status should remain empty
  expect(find.text('Status: '), findsOneWidget);
  });

  testWidgets('saveExportOverride throwing is caught and shows message',
      (WidgetTester tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          saveExportOverride: (path, content) async {
            throw Exception('save failed');
          },
        ),
      ),
    ));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  await tester.pump(const Duration(milliseconds: 200));
  expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('Import returns failure ImportResult shows error',
      (WidgetTester tester) async {
    // Use a FakePersistence that simulates failed import
    final failing = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = true}) async {
      return FakeImportResult(success: false, message: 'import failed', counts: {});
    });
    final repo = MatchRepository(persistence: failing);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {
            'bytes': Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits),
            'name': 'fail.json',
            'autoConfirm': true
          }
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  await tester.pump(const Duration(milliseconds: 200));
  // The persistence implementation returns failure even on dry-run, so
  // we should see the backup validation failure path.
  expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('Import succeeds but repo.loadAll throws shows reload failed',
      (WidgetTester tester) async {
    // Repo that throws on loadAll
    final repo = _ThrowingRepo(FakePersistence());

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {
            'bytes': Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits),
            'name': 'ok.json',
            'autoConfirm': true
          }
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  await tester.pump(const Duration(milliseconds: 200));
  expect(find.textContaining('Import succeeded but failed to reload repository'), findsWidgets);
  });

  testWidgets('Export via saveExportOverride succeeds and shows message',
      (WidgetTester tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    String? calledPath;
    String? calledContent;

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          saveExportOverride: (path, content) async {
            calledPath = path;
            calledContent = content;
            // succeed
            return;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(calledPath, isNotNull);
    expect(calledContent, isNotNull);
    expect(find.textContaining('Exported via override as'), findsWidgets);
  });

  testWidgets('Import with autoConfirm true calls repo.loadAll and shows success',
      (WidgetTester tester) async {
    // Spy repo to detect loadAll calls
    bool loadCalled = false;
    final repo = _SpyRepo(persistence: FakePersistence(), onLoad: () => loadCalled = true);

    await tester.pumpWidget(ChangeNotifierProvider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => {
            'bytes': Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits),
            'name': 'auto.json',
            'autoConfirm': true
          }
        ),
      ),
    ));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(loadCalled, isTrue);
    expect(find.text('Import successful'), findsOneWidget);
  });
}
