import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _ThrowingLoadRepo extends MatchRepository {
  _ThrowingLoadRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('repo load failed (test)');
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('export (IO) without documentsDirOverride calls getDocumentsDirectory()', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final persistence = FakePersistence(exportJsonValue: jsonEncode({'ok': true}));
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call the export path which (without documentsDirOverride) will invoke
    // getDocumentsDirectory() and then exportBackupToFile on the FakePersistence.
    await state.exportBackupForTest(state.context);
    await tester.pumpAndSettle();

    // Expect an Exported to <path> SnackBar or status text to be present.
    expect(find.textContaining('Exported to'), findsWidgets);
  });

  testWidgets('export with pickBackupOverride handles repo.loadAll throwing (shows reload failed)', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Persistence will accept dry-run and full import
    final persistence = FakePersistence();
    final repo = _ThrowingLoadRepo(persistence: persistence);

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 2}})));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'test.json', 'autoConfirm': true},
            readFileBytesOverride: (String path) async => bytes,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call the IO-facing export path which under a pickBackupOverride will
    // execute the import/dry-run flow and then repo.loadAll() which throws.
    await state.exportBackupForTest(state.context);
    await tester.pumpAndSettle();

    expect(find.textContaining('Import succeeded but failed to reload repository'), findsWidgets);
  });
}
