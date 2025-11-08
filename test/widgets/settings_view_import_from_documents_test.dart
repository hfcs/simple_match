import 'dart:typed_data';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  testWidgets('export and importFromDocuments test exercises document import/export paths', (tester) async {
    // Prepare fake persistence that writes to a real temp file when asked
    final fake = FakePersistence(exportJsonValue: '{"hello":1}');

    final repo = MatchRepository(persistence: fake);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repo,
        child: MaterialApp(
          home: SettingsView(
            // Provide a test saveExportOverride and documentsDirOverride so
            // the widget won't call platform APIs during the test.
            saveExportOverride: (String path, String content) async {
              print('TEST: saveExportOverride called with path=$path length=${content.length}');
              final f = io.File('${io.Directory.systemTemp.path}/$path');
              f.writeAsStringSync(content);
              print('TEST: saveExportOverride write complete (sync)');
            },
            documentsDirOverride: () async => io.Directory.systemTemp,
            listBackupsOverride: () async {
              // Create a small temp file and return a list containing it
              final tmp = io.File('${io.Directory.systemTemp.path}/simple_match_test_backup.json');
              await tmp.writeAsString('{"hello":1}');
              return [tmp];
            },
            readFileBytesOverride: (path) async {
              print('TEST: readFileBytesOverride called with path=$path');
              try {
                final f = io.File(path);
                final exists = f.existsSync();
                print('TEST: readFileBytesOverride exists=$exists');
                if (!exists) throw Exception('file does not exist: $path');
                final bytes = f.readAsBytesSync();
                print('TEST: readFileBytesOverride read ${bytes.length} bytes (sync)');
                return Uint8List.fromList(bytes);
              } catch (e, st) {
                print('TEST: readFileBytesOverride exception: $e\n$st');
                rethrow;
              }
            },
          ),
        ),
      ),
    );


  await tester.pumpAndSettle();

  // Call the export path via the test wrapper to exercise exporter->file path
  final stateFinder = find.byType(SettingsView);
  expect(stateFinder, findsOneWidget);

  final state = tester.state(stateFinder) as dynamic;

  // Export should write a file via FakePersistence
  print('TEST: calling exportBackupForTest');
  await state.exportBackupForTest(tester.element(stateFinder));
  print('TEST: exportBackupForTest returned');

  // Now exercise import from documents using the chosen temp file to avoid
  // showing the selection dialog in tests.
  final tmpFile = io.File('${io.Directory.systemTemp.path}/simple_match_test_backup.json');
  // Ensure the tmp file exists (some test paths create it via listBackupsOverride
  // but here we call import helper directly so create it explicitly).
  if (!tmpFile.existsSync()) {
    print('TEST: creating tmpFile at ${tmpFile.path}');
    tmpFile.writeAsStringSync('{"hello":1}');
  }
  print('TEST: calling importFromDocumentsConfirmedForTest with ${tmpFile.path}');
  await state.importFromDocumentsConfirmedForTest(tester.element(stateFinder), repo, fake, tmpFile);
  print('TEST: importFromDocumentsConfirmedForTest returned');

  // Pump briefly to allow any setState updates (avoid waiting for SnackBar animations)
  await tester.pump(const Duration(milliseconds: 100));

    // Verify the status text updated at least once (non-empty)
    print('TEST: verifying status text');
    expect(find.textContaining('Status:'), findsOneWidget);
    print('TEST: done');
  });
}
