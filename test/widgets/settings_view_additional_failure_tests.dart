import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Import flow when persistence throws shows Import error SnackBar', (tester) async {
  SharedPreferences.setMockInitialValues({});
    // FakePersistence that throws during import to exercise the top-level catch
    final persistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      throw Exception('import boom');
    });
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'Explode', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'boom.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect((snack.content as Text).data, contains('Import error'));
  });

  testWidgets('Export Backup with pickBackupOverride exercises import branch and shows success', (tester) async {
  SharedPreferences.setMockInitialValues({});
    // FakePersistence that returns success for both dryRun and import
    final persistence = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
      if (dryRun) {
        return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 1, 'stageResults': 0});
      }
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final backup = {
      'metadata': {'schemaVersion': 2, 'exportedAt': DateTime.now().toIso8601String()},
      'stages': [],
      'shooters': [ {'name': 'FromExport', 'scaleFactor': 1.0} ],
      'stageResults': [],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: () async => {'bytes': bytes, 'name': 'from_export.json', 'autoConfirm': true})),
      ),
    );
    await tester.pump();

    // Trigger the Export Backup flow which contains an early-path using pickBackupOverride
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    // The import path should complete and show a success SnackBar and status
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Import successful'), findsWidgets);
    expect(find.textContaining('Status: Import successful'), findsOneWidget);
  });
}
