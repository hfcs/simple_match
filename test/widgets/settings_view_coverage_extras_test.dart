import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';
import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('Import flow covers extras previously exercised by helpers', (tester) async {
    final fake = FakePersistence(importFn: (bytes, {dryRun = false, backupBeforeRestore = false}) async => FakeImportResult(success: true));
    final repo = MatchRepository(persistence: fake);

    Future<Map<String, dynamic>> pickOverride() async => <String, dynamic>{'bytes': Uint8List.fromList([1,2,3]), 'name': 'import.json', 'autoConfirm': true};

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(pickBackupOverride: pickOverride)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
