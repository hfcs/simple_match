import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// web-safe: this test uses injected overrides and should run on web.
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

// Simple fake file object used by listBackupsOverride to simulate a File-like
// object exposing a `path` property.
class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Export override throwing shows Export failed SnackBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    Future<void> throwingSave(String path, String content) async {
      throw Exception('boom');
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: throwingSave)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    final snackBar = find.byType(SnackBar);
    expect(snackBar, findsOneWidget);
    final snack = tester.widget<SnackBar>(snackBar);
    expect((snack.content as Text).data, contains('Export failed'));
  });

  testWidgets('pickBackupOverride null shows No file selected SnackBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => null)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    final snackBar = find.byType(SnackBar);
    expect(snackBar, findsOneWidget);
    final snack = tester.widget<SnackBar>(snackBar);
    expect((snack.content as Text).data, contains('No file selected'));
  });

  testWidgets('pickBackupOverride with invalid JSON shows validation failure', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final badBytes = Uint8List.fromList(utf8.encode('{}'));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': badBytes, 'name': 'bad.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    final snackBar = find.byType(SnackBar);
    expect(snackBar, findsOneWidget);
    final snack = tester.widget<SnackBar>(snackBar);
    expect((snack.content as Text).data, contains('Backup validation failed'));
  });

  testWidgets('pickBackupOverride shows dialog and restore when not autoConfirm', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Zed', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'zed.json', 'autoConfirm': false})),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Import Backup'));
    await tester.pump();

    // Dialog should be visible asking to confirm
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    // Repo should now contain the imported shooter
    await repo.loadAll();
    expect(repo.getShooter('Zed')?.name, equals('Zed'));
  });

  testWidgets('listBackupsOverride + readFileBytesOverride import flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Yara', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    // simple fake file with path property used by SettingsView (top-level _FakeFile)

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [ _FakeFile('/tmp/yara.json') ],
            readFileBytesOverride: (p) async => bytes,
            // Provide pick override so web runs use the same deterministic path
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'yara.json', 'autoConfirm': false},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The import flow differs on web vs IO. If the pick override/directory
    // path was used we will see a Confirm dialog immediately; otherwise a
    // SimpleDialog lists files. Handle both cases.
    if (find.text('Confirm restore').evaluate().isNotEmpty) {
      await tester.tap(find.text('Restore'));
    } else if (find.byType(SimpleDialogOption).evaluate().isNotEmpty) {
      final option = find.byType(SimpleDialogOption).first;
      await tester.tap(option);
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Confirm restore').evaluate().isNotEmpty) {
        await tester.tap(find.text('Restore'));
      }
    } else {
      // Try to match a filename somewhere in the tree as a last resort
      final fileFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('yara.json'));
      expect(fileFinder, findsOneWidget);
      await tester.tap(fileFinder);
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Confirm restore').evaluate().isNotEmpty) await tester.tap(find.text('Restore'));
    }
    await tester.pump(const Duration(milliseconds: 200));

    await repo.loadAll();
    expect(repo.getShooter('Yara')?.name, equals('Yara'));
  });
}
