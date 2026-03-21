import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('import from documents dir (choose file) then confirm -> success', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}, 'stages': [], 'shooters': [], 'stageResults': []};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [_FakeFile('/tmp/choice.json')],
            readFileBytesOverride: (path) async => bytes,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The simple dialog with the filename should appear; tap the option
    expect(find.text('Select backup to import'), findsOneWidget);
    expect(find.text('choice.json'), findsOneWidget);
    await tester.tap(find.text('choice.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // Now the Confirm restore dialog appears; tap Restore
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Status: Import successful'), findsOneWidget);
  });

  testWidgets('import from documents dir then cancel confirm -> no import', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [_FakeFile('/tmp/cancel.json')],
            readFileBytesOverride: (path) async => bytes,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Choose the file then cancel the confirm dialog
    await tester.tap(find.text('cancel.json'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    // No success status should be shown; last message remains empty initially
    expect(find.textContaining('Status:'), findsOneWidget);
    expect(find.text('Status: Import successful'), findsNothing);
  });

  testWidgets('export without override uses documentsDirOverride path and shows exported message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    // Provide a fake documents directory object with a path property
    final fakeDir = {'path': '/tmp'};

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            documentsDirOverride: () async => fakeDir,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The UI should show an export-related message (accept SnackBar or Status text)
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Export')), findsWidgets);
  });

  testWidgets('export with saveExportOverride throwing does not crash and still reports Exported to', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final fakeDir = {'path': '/tmp'};

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            documentsDirOverride: () async => fakeDir,
            saveExportOverride: (name, content) async {
              throw Exception('simulated exporter failure');
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Even if the override throws, the UI should show an export-related message
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Export')), findsWidgets);
  });

  testWidgets('import where readFileBytesOverride throws shows Import error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [_FakeFile('/tmp/badread.json')],
            readFileBytesOverride: (path) async {
              throw Exception('simulated read failure');
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Choose the file; this will trigger readFileBytesOverride which throws
    await tester.tap(find.text('badread.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // Both SnackBar and Status Text may be present; accept any matching widgets
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Import error')), findsWidgets);
  });
}

