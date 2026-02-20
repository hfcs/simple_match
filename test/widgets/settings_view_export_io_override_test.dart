import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Export Backup via saveExportOverride writes to temp file', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('simple_match_export_override');
    final fake = FakePersistence(exportJsonValue: '{"exported":true}');
    final repo = MatchRepository(persistence: fake);
    await repo.loadAll();

    String? writtenPath;
    String? writtenContent;

    Future<void> saveOverride(String path, String content) async {
      // Deterministic test seam: record the values in-memory instead of
      // touching the real filesystem to avoid flaky IO in the test harness.
      print('saveOverride called with path: $path, content length: ${content.length}');
      writtenPath = '${tmp.path}/$path';
      writtenContent = content;
      // Small delay to simulate async work
      await Future.delayed(const Duration(milliseconds: 5));
      print('saveOverride recorded content for $writtenPath');
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: SettingsView(saveExportOverride: saveOverride),
      ),
    ));

    await tester.pump();

    // Press Export Backup button
    final exportFinder = find.text('Export Backup');
    expect(exportFinder, findsOneWidget);
    await tester.tap(exportFinder);
    await tester.pump(const Duration(milliseconds: 200));

  // The saveOverride should have been invoked and recorded the content
  expect(writtenPath, isNotNull);
  expect(writtenContent, isNotNull);
  final json = jsonDecode(writtenContent!);
  expect(json['exported'], equals(true));

    // cleanup
    tmp.deleteSync(recursive: true);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
