import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  setUp(() {
    // Ensure default is false; tests will toggle when needed.
    SettingsView.forceKIsWeb = false;
  });

  testWidgets('exportViaWebForTest uses exporter and updates status', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');
    final repo = MatchRepository(persistence: fake);

    String? exportedName;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            saveExportOverride: (String name, String content) async {
              exportedName = name;
            },
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Force web behavior and call the web export wrapper.
    SettingsView.forceKIsWeb = true;
    final stateFinder = find.byType(SettingsView);
    final state = tester.state(stateFinder) as dynamic;

    await state.exportViaWebForTest(tester.element(stateFinder), fake, state.widget.saveExportOverride ?? (a,b) async {} , 'ts');
    await tester.pump(const Duration(milliseconds: 200));

    expect(exportedName, isNotNull);
    expect(find.textContaining('Status:'), findsOneWidget);
  });

  testWidgets('importViaWebForTest dry-run failure shows validation', (tester) async {
    // FakePersistence that returns dry-run failure
    final fake = FakePersistence(importFn: (Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
      if (dryRun) return FakeImportResult(success: false, message: 'invalid');
      return FakeImportResult(success: false, message: 'invalid');
    });
    final repo = MatchRepository(persistence: fake);

    bool pickCalled = false;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            pickBackupOverride: () async {
              pickCalled = true;
              return {'bytes': Uint8List.fromList([1,2,3]), 'name': 'x', 'autoConfirm': true};
            },
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    final stateFinder = find.byType(SettingsView);
    final state = tester.state(stateFinder) as dynamic;

    await state.importViaWebForTest(tester.element(stateFinder), repo, fake);
    await tester.pump(const Duration(milliseconds: 200));

    expect(pickCalled, isTrue);
    // Status text should still be present
    expect(find.textContaining('Status:'), findsOneWidget);
  });

  testWidgets('importFromDocumentsConfirmedForTest handles repo.loadAll throwing', (tester) async {
    // Fake that returns success for import, but repo.loadAll throws
    final fake = FakePersistence();
  // Create a tiny fake repo that throws when loadAll is called.
  final repo = _ThrowingLoadRepo(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            listBackupsOverride: () async => [
              // Provide a simple object with a path field
              {'path': '/tmp/nonexistent.json'}
            ],
            // Provide a read override returning empty valid bytes
            readFileBytesOverride: (String path) async => Uint8List.fromList([1,2,3]),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    final stateFinder = find.byType(SettingsView);
    final state = tester.state(stateFinder) as dynamic;

    // Call the chosen-for-test wrapper with a fake chosen object
    final chosen = _SimplePath('/tmp/nonexistent.json');
    await state.importFromDocumentsConfirmedForTest(tester.element(stateFinder), repo, fake, chosen);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Status:'), findsOneWidget);
  });
}

class _SimplePath {
  final String path;
  _SimplePath(this.path);
}

class _ThrowingLoadRepo extends MatchRepository {
  _ThrowingLoadRepo({super.persistence});

  @override
  Future<void> loadAll() async {
    throw Exception('load fail');
  }
}
