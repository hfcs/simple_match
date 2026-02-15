import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
// ignore_for_file: unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _LocalFakeFile {
  final String path;
  _LocalFakeFile(this.path);
  @override
  String toString() => path.split('/').last;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('pickBackupOverride dry-run validation fails shows validation error', (tester) async {
    SharedPreferences.setMockInitialValues({});
  final payload = {'bad': true};
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid backup', counts: {});
      return FakeImportResult(success: true, message: 'ok', counts: {});
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'bad.json', 'autoConfirm': true},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup validation failed'), findsOneWidget);
  });

  testWidgets('IO readFileBytes throws leads to Import error UI', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

  final fakeFile = _LocalFakeFile('/app/documents/simple_match_backup.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [fakeFile],
            readFileBytesOverride: (path) async {
              throw Exception('read failed');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

  // Choose the only option (name generation uses toString() of the object)
  expect(find.text('simple_match_backup.json'), findsOneWidget);
  await tester.tap(find.text('simple_match_backup.json'));
    await tester.pumpAndSettle();

    // Both the Status text and a SnackBar may contain the message; accept either.
    expect(find.textContaining('Import error'), findsWidgets);
  });

  testWidgets('listBackupsOverride empty shows no backup files found message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Ensure UI updates settle and use contains-based matcher for stability.
    await tester.pumpAndSettle();
    expect(find.textContaining('No backup files found'), findsOneWidget);
  });
}
