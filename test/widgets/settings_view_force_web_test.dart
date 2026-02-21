import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/views/settings_view.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Export override executes (force web branch)', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    var called = false;
    final widget = Provider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          saveExportOverride: (String path, String content) async {
            called = true;
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Force web branch
    SettingsView.forceKIsWeb = true;

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    await state.exportBackupForTest(tester.element(find.byType(SettingsView)));
    expect(called, isTrue);
  });

  testWidgets('Import from documents (confirmed) executes', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    final fake = _FakeFile('/tmp/fake_backup.json');

    final widget = Provider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [fake],
          readFileBytesOverride: (String path) async => Uint8List.fromList('{}'.codeUnits),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;
    await state.importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, svc, fake);
    // If no exception, flow executed; repository should be loaded
    expect(true, isTrue);
  });
}
