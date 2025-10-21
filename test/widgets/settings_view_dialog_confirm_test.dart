import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    // Confirm dialog should appear
    expect(find.text('Confirm restore'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

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
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    expect(find.text('No backup files found in app documents directory'), findsOneWidget);
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
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // Dialog lists the file name
    expect(find.text('fake_restore.json'), findsOneWidget);

    // Select the file
    await tester.tap(find.text('fake_restore.json'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Confirm restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

  expect(find.text('Import successful'), findsOneWidget);
  });
}
