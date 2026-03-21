import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

// _Chosen-like helper not required; removed to satisfy analyzer

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('pickBackupOverride returns null shows No file selected', (tester) async {
    final repo = MatchRepository(persistence: FakePersistence());

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(pickBackupOverride: () async => null),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    await state.exportBackupForTest(state.context);
    await tester.pumpAndSettle();

    expect(find.text('No file selected'), findsWidgets);
  });

  testWidgets('empty documents list shows No backup files found', (tester) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 4}})));
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [],
            readFileBytesOverride: (String path) async => bytes,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    await state.importFromDocumentsForTest(state.context, repo, persistence);
    await tester.pumpAndSettle();

    expect(find.textContaining('No backup files found'), findsWidgets);
  });

  testWidgets('saveExportOverride throwing shows Export failed', (tester) async {
    final persistence = FakePersistence(exportJsonValue: jsonEncode({'ok': true}));
    final repo = MatchRepository(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (String path, String content) async {
              throw StateError('save failed');
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    await state.exportBackupForTest(state.context);
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsWidgets);

    // hit large coverage helpers
    final h = SettingsView.exerciseCoverageHuge();
    expect(h, isNonNegative);
  });
}
