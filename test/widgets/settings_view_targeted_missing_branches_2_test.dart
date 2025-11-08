import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('import-from-documents with empty list shows expected message', (tester) async {
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

    await tester.pumpAndSettle();

    // Call the test wrapper that exercises the documents import path.
    final state = tester.state(find.byType(SettingsView)) as dynamic;
    await state.importFromDocumentsForTest(state.context, repo, persistence);
    await tester.pumpAndSettle();

    // Exact message in code may vary slightly; use a contains-based matcher
    // and ensure UI settles before asserting.
    await tester.pumpAndSettle();
    expect(find.textContaining('No backup files found'), findsOneWidget);
  });

  testWidgets('pickBackupOverride null -> Import Backup shows No file selected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

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

    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.text('No file selected'), findsOneWidget);
  });

  testWidgets('saveExportOverride throws -> Export failed shown', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = FakePersistence(exportJsonValue: '{}');
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (String name, String json) async {
              throw Exception('exporter fail');
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

  // The code catches exceptions and shows a SnackBar with 'Export failed: '
  // The message may appear in multiple places (status label and SnackBar),
  // so assert that at least one widget contains the text.
  expect(find.textContaining('Export failed'), findsWidgets);
  });
}
