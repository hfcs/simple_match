import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('shim: invoke _exportViaWeb through state to exercise web export branch', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    // Provide a fake exporter that records calls (no actual browser).
    final called = <String, String>{};
    Future<void> fakeExporter(String path, String content) async {
      called['path'] = path;
      called['content'] = content;
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(),
      ),
    ));

    final state = tester.state(find.byType(SettingsView));
    await (state as dynamic).exportViaWebForTest(tester.element(find.byType(SettingsView)), fake, fakeExporter, 'ts123');
    await tester.pumpAndSettle();

    expect(called['path'], isNotNull);
    expect(called['content'], contains('ok'));
  });
}
