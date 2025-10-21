import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo(PersistenceService svc) : super(persistence: svc);
  @override
  Future<void> loadAll() async {
    throw Exception('reload failed');
  }
}

class _FailingPersistence extends PersistenceService {
  _FailingPersistence(SharedPreferences prefs) : super(prefs: prefs);

  @override
  Future<ImportResult> importBackupFromBytes(Uint8List bytes,
      {bool dryRun = false, bool backupBeforeRestore = true}) async {
    return ImportResult(success: false, message: 'import failed', counts: {});
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Import dry-run with invalid JSON shows error message',
      (WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final svc = PersistenceService(prefs: prefs);
  final repo = MatchRepository(persistence: svc);

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
    await tester.pumpAndSettle();

  // Since import dry-run fails validation, expect a validation failure SnackBar
  await tester.pumpAndSettle();
  expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('pickBackupOverride autoConfirm=false shows confirm dialog',
      (WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final svc = PersistenceService(prefs: prefs);
  final repo = MatchRepository(persistence: svc);

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
    await tester.pumpAndSettle();

  // Should see a confirmation dialog
  expect(find.text('Confirm restore'), findsOneWidget);

  // Cancel the dialog
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  // After cancelling, the status should remain empty
  expect(find.text('Status: '), findsOneWidget);
  });

  testWidgets('saveExportOverride throwing is caught and shows message',
      (WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final svc = PersistenceService(prefs: prefs);
  final repo = MatchRepository(persistence: svc);

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
    await tester.pumpAndSettle();

  await tester.pumpAndSettle();
  expect(find.textContaining('Export failed'), findsWidgets);
  });

  testWidgets('Import returns failure ImportResult shows error',
      (WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final svc = _FailingPersistence(prefs);
  final repo = MatchRepository(persistence: svc);

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
    await tester.pumpAndSettle();

  await tester.pumpAndSettle();
  // The persistence implementation returns failure even on dry-run, so
  // we should see the backup validation failure path.
  expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('Import succeeds but repo.loadAll throws shows reload failed',
      (WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final svc = PersistenceService(prefs: prefs);
  final repo = _ThrowingRepo(svc);

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
    await tester.pumpAndSettle();

  await tester.pumpAndSettle();
  expect(find.textContaining('Import succeeded but failed to reload repository'), findsWidgets);
  });

  testWidgets('Export via saveExportOverride succeeds and shows message',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

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
    await tester.pumpAndSettle();

    expect(calledPath, isNotNull);
    expect(calledContent, isNotNull);
    expect(find.textContaining('Exported via override as'), findsWidgets);
  });

  testWidgets('Import with autoConfirm true calls repo.loadAll and shows success',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Spy repo to detect loadAll calls
    bool loadCalled = false;
    final repo = _SpyRepo(persistence: svc, onLoad: () => loadCalled = true);

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
    await tester.pumpAndSettle();

    expect(loadCalled, isTrue);
    expect(find.text('Import successful'), findsOneWidget);
  });
}
