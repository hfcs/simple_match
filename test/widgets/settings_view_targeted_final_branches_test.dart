import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _DirLike { final String path; _DirLike(this.path); }

class _ChosenFile { final String path; _ChosenFile(this.path); }

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SettingsView.suppressSnackBarsInTests = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    SettingsView.suppressSnackBarsInTests = false;
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('importFromDocumentsChosenForTest and confirmed import exercise branches', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            readFileBytesOverride: (String p) async => Uint8List.fromList([1,2,3]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    final chosen = _ChosenFile('/tmp/simple_match_backup.json');

    // Exercise the flow that shows confirmation dialog path (we'll bypass dialog by calling the chosen-for-test helper then cancelling via confirm override)
    await state.importFromDocumentsChosenForTest(state.context, repo, persistence, chosen);
    await tester.pumpAndSettle();

    // Exercise the confirm-free import helper which directly proceeds
    await state.importFromDocumentsConfirmedForTest(state.context, repo, persistence, chosen);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsView), findsOneWidget);
  });

  testWidgets('exportBackupForTest IO path uses documentsDirOverride and completes', (tester) async {
    final persistence = FakePersistence();
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            documentsDirOverride: () async => _DirLike('/tmp'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    await state.exportBackupForTest(state.context);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsView), findsOneWidget);
  });
}
