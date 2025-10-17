import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

// Lightweight TestPersistence for widget tests that avoids heavy IO.
class TestPersistence extends PersistenceService {
  final String tmpBase;
  TestPersistence(this.tmpBase, {super.prefs});
  @override
  Future<File> exportBackupToFile(String path) async {
    final f = File(path);
    await f.parent.create(recursive: true);
    await f.writeAsString('{}');
    return f;
  }

  @override
  Future<String> exportBackupJson() async => '{}';
}

void main() {
  testWidgets('Pressing Export Backup calls saveExportOverride', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Prepare temp dir and mock path_provider to point to it
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');
    const channelName = 'plugins.flutter.io/path_provider';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), (methodCall) async {
      return tmpDir.path;
    });

    final persistence = TestPersistence(tmpDir.path, prefs: prefs);
    final repo = MatchRepository(persistence: persistence);
    await repo.loadAll();

    final completer = Completer<void>();
    var called = false;
    Future<void> fakeSaveExport(String path, String contents) async {
      called = true;
      if (!completer.isCompleted) completer.complete();
      // no disk write here; test records invocation
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: fakeSaveExport)),
      ),
    );

    await tester.pump();

    final exportButton = find.text('Export Backup');
    expect(exportButton, findsOneWidget);

    await tester.tap(exportButton);
    await tester.pump();

    // allow async operations to run
    // Wait for fakeSaveExport to be called, or timeout after 2s
    try {
      await completer.future.timeout(const Duration(seconds: 2));
    } catch (_) {}

    expect(called, isTrue, reason: 'saveExportOverride should be invoked when Export Backup is tapped');
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  // Clear any method channel mocks to avoid interfering with other tests
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel('plugins.flutter.io/path_provider'), null);
  });
}
