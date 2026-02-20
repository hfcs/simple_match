import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

// Subclass MatchRepository at top-level so tests can override behavior like
// loadAll() to throw for specific test scenarios.
class _ThrowingRepo extends MatchRepository {
  _ThrowingRepo({super.persistence});
  @override
  Future<void> loadAll() async => throw Exception('boom');
}

void main() {
  testWidgets('Import: pickBackupOverride null shows No file selected', (tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(pickBackupOverride: () async => null),
        ),
      ),
    );

  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No file selected'), findsWidgets);
  });

  testWidgets('Import: pickBackupOverride dry-run failure shows validation failed', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    // Provide a pickBackupOverride that returns a map with bytes and a name
    Future<Map<String, dynamic>> pickOverride() async => <String, dynamic>{'bytes': Uint8List.fromList([1, 2, 3]), 'name': 'bad.json', 'autoConfirm': true};

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(pickBackupOverride: pickOverride),
        ),
      ),
    );

  await tester.pump(const Duration(milliseconds: 200));
  // Trigger import backup via button
  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Expect validation failed snackbar
    expect(find.textContaining('Backup validation failed'), findsWidgets);
  });

  testWidgets('Import: repo.loadAll throws shows reload-failed message', (tester) async {
    // Create a repo whose loadAll throws after import
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async {
      return FakeImportResult(success: true);
    });

    final repo = _ThrowingRepo(persistence: fake);
    Future<Map<String, dynamic>> pickOverride() async => <String, dynamic>{'bytes': Uint8List.fromList([9, 9, 9]), 'name': 'good.json', 'autoConfirm': true};

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(pickBackupOverride: pickOverride),
        ),
      ),
    );

  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Expect import succeeded but reload failed snackbar
    expect(find.textContaining('reload failed'), findsWidgets);
  });

  testWidgets('Export: saveExportOverride path exercised', (tester) async {
  final fake = FakePersistence(exportJsonValue: '{"ok":true}');
  final repo = MatchRepository(persistence: fake);

    var recordedName = '';
    Future<void> saveOverride(String name, String content) async {
      recordedName = name;
      // write to a temp file to simulate save
      final file = File('${Directory.systemTemp.path}/$name');
      await file.create(recursive: true);
      await file.writeAsString(content);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(saveExportOverride: saveOverride),
        ),
      ),
    );

  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  expect(recordedName.isNotEmpty, isTrue);
  });
}
