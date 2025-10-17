import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/export_utils_io.dart' as export_io;

void main() {
  test('saveExport writes file with expected content', () async {
    final tmpDir = Directory.systemTemp.createTempSync('sm_save_export_');
    final outPath = '${tmpDir.path}/export_test_output.json';
    final content = 'hello-export';

    await export_io.saveExport(outPath, content);

    final f = File(outPath);
    expect(f.existsSync(), isTrue);
    final read = await f.readAsString();
    expect(read, equals(content));

    tmpDir.deleteSync(recursive: true);
  });
}
