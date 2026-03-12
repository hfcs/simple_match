import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';
import 'package:simple_match/views/settings_view.dart';

class _FakeDir {
  final String path;
  _FakeDir(this.path);
}

void main() {
  testWidgets('documentsDir override branch executes', (tester) async {
    SettingsView.suppressSnackBarsInTests = true;

    final repo = MatchRepository(persistence: FakePersistence(exportJsonValue: '{}'));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            // inject a fake documents directory to exercise the branch
            documentsDirOverride: _fakeDocDir,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    // invoke the public export wrapper which will call into _documentsDir()
    await state.exportBackupForTest(tester.element(find.byType(SettingsView)));
    await tester.pumpAndSettle();

    // verify the status text updated (contains 'Exported')
    final exportedText = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Exported'));
    expect(exportedText, findsOneWidget);
  });
}

Future<dynamic> _fakeDocDir() async => _FakeDir('/tmp/fake_docs');
