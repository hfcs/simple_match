import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/io_file_helpers_io.dart';

void main() {
  test('listBackups finds json files in mocked documents directory', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tmpDir = Directory.systemTemp.createTempSync('sm_test_docs_');
    final file = File('${tmpDir.path}/sm_list_backup.json');
    await file.writeAsString('{}');

    const channelName = 'plugins.flutter.io/path_provider';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), (mc) async {
      return tmpDir.path;
    });

    final files = await listBackups();
    expect(files.isNotEmpty, isTrue);
    final names = files.map((f) => f.path.split('/').last).toList();
    expect(names, contains('sm_list_backup.json'));

    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channelName), null);
  });
}
