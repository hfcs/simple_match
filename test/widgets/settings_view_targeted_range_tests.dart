import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _F { final String path; _F(this.path); }

class _ThrowRepo extends MatchRepository {
  _ThrowRepo(FakePersistence p): super(persistence: p);
  @override
  Future<void> loadAll() async { throw Exception('boom load'); }
}

void main() {
  testWidgets('Web-pick branch: autoConfirm false -> confirm dialog then success', (tester) async {
    final payload = {'metadata': {'schemaVersion': 2}};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 2, 'shooters': 1, 'stageResults': 0});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'w.json', 'autoConfirm': false},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // confirm dialog should appear
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import successful')), findsWidgets);
  });

  testWidgets('Web-pick branch: dry-run failure shows validation failed', (tester) async {
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': Uint8List.fromList([1]), 'name': 'x.json'})),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Backup validation failed')), findsWidgets);
  });

  testWidgets('Documents-list pick -> choose file, confirm -> repo.loadAll throws (reload failed path)', (tester) async {
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: true);
    });

    final repo = _ThrowRepo(fake);

    final f = _F('/tmp/pick.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [f],
            readFileBytesOverride: (p) async => Uint8List.fromList([2,3,4]),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // choose
    await tester.tap(find.text('pick.json'));
    await tester.pump(const Duration(milliseconds: 200));

    // confirm
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

    // should show reload failed status
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('reload failed')), findsWidgets);
  });

  testWidgets('Documents-list pick -> readFileBytesOverride throws (Import error)', (tester) async {
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async => FakeImportResult(success: true));
    final repo = MatchRepository(persistence: fake);
    final f = _F('/tmp/err.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [f],
            readFileBytesOverride: (p) async => throw Exception('boom read'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('err.json'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Import error')), findsWidgets);
  });

  testWidgets('Documents-list pick -> dry-run failure path (Backup validation failed)', (tester) async {
    final fake = FakePersistence(importFn: (b, {dryRun = false, backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'bad dry');
      return FakeImportResult(success: true);
    });
    final repo = MatchRepository(persistence: fake);
    final f = _F('/tmp/baddry.json');

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [f],
            readFileBytesOverride: (p) async => Uint8List.fromList([9]),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('baddry.json'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toString().contains('Backup validation failed')), findsWidgets);
  });
}
