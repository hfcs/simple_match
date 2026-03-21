import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FailingLoadRepo extends MatchRepository {
  _FailingLoadRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('repo load failed (suppressed test)');
  }
}

class _FakeChosen {
  final String path;
  _FakeChosen(this.path);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('repo.loadAll throws with suppressSnackBarsInTests=true', (tester) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 4}})));

    // Persistence returns success for full import so loadAll() will be called
    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = _FailingLoadRepo(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            readFileBytesOverride: (String path) async => bytes,
            // listBackupsOverride not required since we call the confirmed helper
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    SettingsView.suppressSnackBarsInTests = true;
    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call the confirmed import helper which will trigger repo.loadAll() and
    // the repo will throw, exercising the reload-failed branch.
    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, _FakeChosen('/tmp/fake.json'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import succeeded, reload failed'), findsWidgets);

    SettingsView.suppressSnackBarsInTests = false;
  });
}
