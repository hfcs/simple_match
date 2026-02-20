import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

class _FakeFileObj {
  final String path;
  _FakeFileObj(this.path);
}

class ThrowingRepo extends MatchRepository {
  ThrowingRepo({super.persistence});
  @override
  Future<void> loadAll() async {
    throw Exception('reload failed');
  }
}

void main() {
  testWidgets('importViaWebForTest: final import failure shows Import failed', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      // dry-run succeeds
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      // actual import fails
      return FakeImportResult(success: false, message: 'import failed');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          // Provide a deterministic web picker so no dialog is shown
          pickBackupOverride: () async => {
            'bytes': Uint8List.fromList([1, 2, 3]),
            'name': 'webpick.json',
            'autoConfirm': true,
          },
        ),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    // Call the web import wrapper directly; it should show the Import failed path
    await (state as dynamic).importViaWebForTest(tester.element(find.byType(SettingsView)), repo, fake);
    await tester.pump(const Duration(milliseconds: 200));

  // The SettingsView always renders the last status line in the UI
  // as "Status: <message>" so assert the status text contains the
  // failure marker to avoid matching SnackBar duplicates.
  expect(find.textContaining('Status: Import failed'), findsOneWidget);
  });

  testWidgets('importFromDocumentsConfirmedForTest: final import failure sets message', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
      return FakeImportResult(success: false, message: 'final fail');
    });

    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(
          readFileBytesOverride: (p) async => Uint8List.fromList('{}'.codeUnits),
        ),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));

    final chosen = _FakeFileObj('/tmp/dummy.json');

    await (state as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pump(const Duration(milliseconds: 200));

  expect(find.textContaining('Status: Import failed'), findsOneWidget);
  });

  testWidgets('importFromDocumentsChosenForTest: repo.loadAll throws shows reload failed', (tester) async {
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: true, counts: {'stages': 1, 'shooters': 1, 'stageResults': 1});
      return FakeImportResult(success: true);
    });

    final repo = ThrowingRepo(persistence: fake);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(readFileBytesOverride: (p) async => Uint8List.fromList('{}'.codeUnits)),
      ),
    ));
    await tester.pump();

    final state = tester.state(find.byType(SettingsView));
    final chosen = _FakeFileObj('/tmp/ok.json');

  // Use the "Confirmed" helper to avoid showing a confirmation dialog
  // (which would block the test). The Confirmed variant reads the bytes
  // and proceeds directly to the import step.
  await (state as dynamic).importFromDocumentsConfirmedForTest(tester.element(find.byType(SettingsView)), repo, fake, chosen);
    await tester.pump(const Duration(milliseconds: 200));

    // Check the Status text specifically (SnackBar contains a similar
    // message so matching the Status avoids duplicate matches).
    expect(find.textContaining('Status: Import succeeded, reload failed'), findsOneWidget);
  });
}
