import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

class _FakeDir {
  final String path;
  _FakeDir(this.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('maybeShowSnackBar and documentsDir branch', (tester) async {
    final repo = MatchRepository();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: Scaffold(body: SettingsView(documentsDirOverride: () async => _FakeDir('/tmp'))),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    // Call the private method to show a SnackBar and ensure it appears
    (state as dynamic)._maybeShowSnackBar(tester.element(find.byType(SettingsView)), const SnackBar(content: Text('test-snack')));
    await tester.pumpAndSettle();
    expect(find.text('test-snack'), findsOneWidget);

    // Call documentsDir() which should invoke our override and return an object with .path
    final dir = await (state as dynamic)._documentsDir();
    expect(dir.path, '/tmp');
  });
}
