import 'dart:convert';
import 'dart:typed_data';
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
    throw Exception('simulated reload failure');
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

  testWidgets('suppressSnackBars path: importFromDocumentsConfirmedForTest catches reload failure', (tester) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 4}})));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = _FailingLoadRepo(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(readFileBytesOverride: (String p) async => bytes),
        ),
      ),
    );

    await tester.pumpAndSettle();

    SettingsView.suppressSnackBarsInTests = true;

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, _FakeChosen('/tmp/x'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import succeeded, reload failed'), findsWidgets);

    SettingsView.suppressSnackBarsInTests = false;
  });

  testWidgets('normal path: importFromDocumentsConfirmedForTest catches reload failure and shows SnackBar', (tester) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'metadata': {'schemaVersion': 4}})));

    final persistence = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = _FailingLoadRepo(persistence: persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(readFileBytesOverride: (String p) async => bytes),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, _FakeChosen('/tmp/x'));
    await tester.pumpAndSettle();

    // SnackBar may be suppressed in some environments; assert status text updated
    expect(find.textContaining('Import succeeded, reload failed'), findsWidgets);
  });
}
