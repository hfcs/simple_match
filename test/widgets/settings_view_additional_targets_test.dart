import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

// Small fake file used by listBackupsOverride
class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  testWidgets('exportBackupForTest triggers web-export branch when forced web', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    // Force the widget to treat platform as web for test-only branches.
    SettingsView.forceKIsWeb = true;

    String? recordedName;
    Future<void> exporter(String name, String content) async {
      recordedName = name;
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(),
      ),
    ));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView));
    // Call the test wrapper which will go into the kIsWeb branch and call
    // the web exporter (via the test-only exportViaWebForTest wrapper).
    await (state as dynamic).exportViaWebForTest(tester.element(find.byType(SettingsView)), fake, exporter, 'ZZZ');
    await tester.pumpAndSettle();

    expect(recordedName, isNotNull);

    SettingsView.forceKIsWeb = false;
  });

  testWidgets('importViaWebForTest shows confirm dialog and Cancel returns without import', (tester) async {
    final payload = Uint8List.fromList('{}'.codeUnits);
    final fake = FakePersistence(importFn: (Uint8List b, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 2, 'shooters': 1, 'stageResults': 0});
      return FakeImportResult(success: true);
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    Future<Map<String, dynamic>?> pick() async => {'bytes': payload, 'name': 'cancel_me.json', 'autoConfirm': false};

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(pickBackupOverride: pick),
      ),
    ));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SettingsView));
    final future = (state as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);

    // Let dialog appear
    await tester.pumpAndSettle();

    // Tap Cancel instead of Restore
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await future;

    // No success message should be present
    expect(find.textContaining('Import successful'), findsNothing);
  });
}
