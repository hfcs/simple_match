
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/settings_view.dart';
import 'package:simple_match/repository/match_repository.dart';

import 'test_helpers/fake_repo_and_persistence.dart';

void main() {
  const channelName = 'plugins.flutter.io/path_provider';

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // On web we won't touch path_provider; other platforms will ignore this.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  testWidgets('Import Backup shows no-files SnackBar when documents dir empty', (tester) async {
    // Use the listBackupsOverride to return an empty list so the import flow
    // displays the 'no backups' SnackBar without touching the filesystem.
  final repo = MatchRepository(persistence: FakePersistence());
  await repo.loadAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(listBackupsOverride: () async => [], pickBackupOverride: () async => null)),
      ),
    );

    await tester.pump();

  final importFinder = find.text('Import Backup');
    expect(importFinder, findsOneWidget);
    await tester.tap(importFinder);
    await tester.pumpAndSettle();

    // SnackBar should appear indicating no backup files or that the user
    // cancelled the file picker on web. Match either message.
    final msgFinder = find.byWidgetPredicate((w) => w is Text && ((w.data ?? '').contains('No backup') || (w.data ?? '').contains('No file')));
    expect(msgFinder, findsOneWidget);
  });
}
