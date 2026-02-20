// Avoid using dart:io Directory creation which caused timeouts in CI runs.
// Return a lightweight object with a `path` property via documentsDirOverride.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';
import 'test_helpers/fake_repo_and_persistence.dart';


void main() {
  testWidgets('export uses saveExportOverride and shows exported message', (tester) async {
    final fake = FakePersistence(exportJsonValue: '{"ok":true}');

    var savedName = '';
    var savedContent = '';
    Future<void> saveOverride(String name, String content) async {
      savedName = name;
      savedContent = content;
    }

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MatchRepository>.value(
        value: MatchRepository(persistence: fake),
        child: SettingsView(saveExportOverride: saveOverride),
      ),
    ));

    // Trigger export which should use the override and set status
    await tester.tap(find.text('Export Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // The status text should indicate an export via override
    expect(find.textContaining('Exported via override as'), findsWidgets);
    expect(savedName.isNotEmpty, isTrue);
    expect(savedContent.isNotEmpty, isTrue);
  });
}
