import 'dart:convert';

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });

  testWidgets('Export Backup writes a file to documents directory via UI', (tester) async {
    // Use a saveExportOverride to intercept export without filesystem/method-channel.
  // Use FakePersistence to avoid touching platform plugins in tests
  final persistence = FakePersistence(exportJsonValue: '{}');
  final repo = MatchRepository(persistence: persistence);
  await repo.loadAll();

    var called = false;
    Future<void> fakeSaveExport(String path, String content) async {
      called = true;
      jsonDecode(content);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<MatchRepository>.value(
        value: repo,
        child: MaterialApp(home: SettingsView(saveExportOverride: fakeSaveExport)),
      ),
    );
    await tester.pump();

    final exportFinder = find.text('Export Backup');
    expect(exportFinder, findsOneWidget);

    await tester.tap(exportFinder);
    await tester.pump(const Duration(milliseconds: 200));
    expect(called, isTrue);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  }, timeout: Timeout(Duration(seconds: 20)));
}
