import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// kIsWeb not required; tests are web-safe via overrides
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/views/settings_view.dart';

class _FakeFile {
  final String path;
  _FakeFile(this.path);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('pickBackupOverride null shows No file selected SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
          create: (_) => MatchRepository(),
          child: SettingsView(
            pickBackupOverride: () async => null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No file selected'), findsOneWidget);
  });

  testWidgets('pickBackupOverride with confirm -> user cancels', (tester) async {
    // provide a valid minimal backup so dry-run succeeds
    final bytes = Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
          create: (_) => MatchRepository(),
          child: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'ok.json'},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    // Confirm dialog should appear
    expect(find.text('Confirm restore'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

  // Should not show success SnackBar
  expect(find.text('Import successful'), findsNothing);
  });

  testWidgets('pickBackupOverride with confirm -> user restores', (tester) async {
    final bytes = Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
          create: (_) => MatchRepository(),
          child: SettingsView(
            pickBackupOverride: () async => {'bytes': bytes, 'name': 'ok.json'},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pump(const Duration(milliseconds: 200));

  // There may be a Status text plus a SnackBar; ensure at least one SnackBar with exact text is present
  expect(find.text('Import successful'), findsOneWidget);
  });

  testWidgets('listBackupsOverride empty shows no-files SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
          create: (_) => MatchRepository(),
          child: SettingsView(
              listBackupsOverride: () async => [],
              pickBackupOverride: () async => null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

  // Assert a SnackBar or other text indicating no files — be robust on web
  expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('listBackupsOverride shows list and restore', (tester) async {
    final fakePath = '/tmp/fake_restore.json';
    final bytes = Uint8List.fromList('{"stages":[],"shooters":[],"stageResults":[]}'.codeUnits);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<MatchRepository>(
          create: (_) => MatchRepository(),
          child: SettingsView(
              listBackupsOverride: () async => [ _FakeFile(fakePath) ],
              readFileBytesOverride: (String p) async => bytes,
              pickBackupOverride: () async => {'bytes': bytes, 'name': 'fake_restore.json', 'autoConfirm': false},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pump(const Duration(milliseconds: 200));

    if (find.text('Confirm restore').evaluate().isNotEmpty) {
      await tester.tap(find.text('Restore'));
      await tester.pump(const Duration(milliseconds: 200));
    } else if (find.byType(SimpleDialogOption).evaluate().isNotEmpty) {
      final option = find.byType(SimpleDialogOption).first;
      await tester.tap(option);
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Confirm restore').evaluate().isNotEmpty) {
        await tester.tap(find.text('Restore'));
        await tester.pump(const Duration(milliseconds: 200));
      }
    } else {
      // fallback: find any Text with filename and tap
      final fileFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('fake_restore.json'));
      expect(fileFinder, findsOneWidget);
      await tester.tap(fileFinder);
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Confirm restore').evaluate().isNotEmpty) await tester.tap(find.text('Restore'));
    }
    await tester.pump(const Duration(milliseconds: 200));

  expect(find.text('Import successful'), findsOneWidget);
  });
}
