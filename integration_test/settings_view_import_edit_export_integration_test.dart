import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/views/stage_input_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Import backup, enter a stage score, then export updated backup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: persistence);

    // Prepare a backup file with one stage and one shooter.
    final docsDir = Directory.systemTemp.createTempSync('sm_integrated_');
    final backup = {
      'metadata': {
        'schemaVersion': 4,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'stages': [
        {'stage': 1, 'scoringShoots': 10, 'createdAtUtc': DateTime.now().toUtc().toIso8601String(), 'updatedAtUtc': DateTime.now().toUtc().toIso8601String()},
      ],
      'shooters': [
        {'name': 'IntegrationShooter', 'scaleFactor': 1.0, 'createdAtUtc': DateTime.now().toUtc().toIso8601String(), 'updatedAtUtc': DateTime.now().toUtc().toIso8601String()},
      ],
      'stageResults': [],
    };
    final file = File('${docsDir.path}/sm_integration_backup.json');
    await file.writeAsString(jsonEncode(backup));

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(
          listBackupsOverride: () async => [file],
          readFileBytesOverride: (path) async => await File(path).readAsBytes(),
        )),
      ),
    );
    await tester.pumpAndSettle();

    // Import the backup using the SettingsView import dialog.
    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    final optionFinder = find.widgetWithText(SimpleDialogOption, file.path.split(Platform.pathSeparator).last);
    expect(optionFinder, findsOneWidget);
    await tester.tap(optionFinder);
    await tester.pumpAndSettle();

    final restoreFinder = find.widgetWithText(TextButton, 'Restore');
    expect(restoreFinder, findsOneWidget);
    await tester.tap(restoreFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Confirm the repository now contains the imported shooter and stage.
    expect(repo.shooters.any((s) => s.name == 'IntegrationShooter'), isTrue);
    expect(repo.stages.any((s) => s.stage == 1), isTrue);

    // Now navigate to StageInputView and submit a score.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MatchRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => StageInputViewModel(repo)),
        ],
        child: const MaterialApp(home: StageInputView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stageSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stage 1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shooterSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IntegrationShooter').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('timeField')), '12.34');
    await tester.enterText(find.byKey(const Key('aField')), '10');
    await tester.enterText(find.byKey(const Key('cField')), '0');
    await tester.enterText(find.byKey(const Key('dField')), '0');
    await tester.enterText(find.byKey(const Key('missesField')), '0');
    await tester.enterText(find.byKey(const Key('noShootsField')), '0');
    await tester.enterText(find.byKey(const Key('procErrorsField')), '0');
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('submitButton'));
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Export the updated backup and verify stageResults now contains an entry.
    final exportedJson = await persistence.exportBackupJson();
    final exported = jsonDecode(exportedJson) as Map<String, dynamic>;
    final stageResults = exported['stageResults'] as List<dynamic>;

    expect(stageResults, hasLength(1));
    expect((stageResults.first as Map<String, dynamic>)['shooter'], 'IntegrationShooter');

    // Cleanup.
    try {
      await file.delete();
      await docsDir.delete(recursive: true);
    } catch (_) {}
  });
}
