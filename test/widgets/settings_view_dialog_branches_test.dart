import 'dart:typed_data';
import 'dart:convert';

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

  testWidgets('Import via web shows confirm dialog and Restore proceeds', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    final picked = {
      'name': 'test.json',
      'bytes': Uint8List.fromList(utf8.encode(jsonEncode({'stages': [], 'shooters': [], 'stageResults': []}))),
    };

    final widget = Provider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          pickBackupOverride: () async => picked,
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    // Call importViaWebForTest and then interact with the confirmation dialog
    final future = state.importViaWebForTest(tester.element(find.byType(SettingsView)), repo, svc);
    await tester.pump();
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    await future;

    // If we reached here without error the branch executed
    expect(true, isTrue);
  });

  testWidgets('Import from documents shows selection dialog and proceeds', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    final fake = _FakeFile('/tmp/fake_backup.json');

    final widget = Provider<MatchRepository>.value(
      value: repo,
      child: MaterialApp(
        home: SettingsView(
          listBackupsOverride: () async => [fake],
          readFileBytesOverride: (String path) async => Uint8List.fromList(utf8.encode(jsonEncode({'stages': [], 'shooters': [], 'stageResults': []}))),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView)) as dynamic;

    final future = state.importFromDocumentsForTest(tester.element(find.byType(SettingsView)), repo, svc);
    await tester.pump();
    // The SimpleDialog lists the file name
    expect(find.text('fake_backup.json'), findsOneWidget);
    await tester.tap(find.text('fake_backup.json'));
    await tester.pump();
    // Now confirm dialog should appear
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    await future;

    expect(true, isTrue);
  });
}
