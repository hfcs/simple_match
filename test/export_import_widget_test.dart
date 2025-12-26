import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  testWidgets('Widget-hosted Export->Import flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);

    // Seed data
    await repo.addShooter(Shooter(name: 'WidgetBob', scaleFactor: 1.0));

    String captured = '';
    Future<void> fakeExport(String path, String contents) async {
      captured = contents;
    }

    // Pump SettingsView with provider and override (provider inside MaterialApp.home)
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>.value(
          value: repo,
          child: SettingsView(saveExportOverride: fakeExport),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final exportBtn = find.text('Export Backup');
    expect(exportBtn, findsOneWidget);

    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    expect(captured, isNotEmpty);

    // Now import captured bytes via persistence
    final bytes = Uint8List.fromList(utf8.encode(captured));
    final res = await persistence.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: true);
    expect(res.success, isTrue);

    // Reload repo and assert shooter exists
    await repo.loadAll();
    final s = repo.getShooter('WidgetBob');
    expect(s, isNotNull);
  });
}
