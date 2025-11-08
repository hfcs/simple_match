import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/export_utils_web.dart' if (dart.library.io) 'package:simple_match/views/export_utils_io.dart' as export_utils;

void main() {
  test('saveExport writes file with expected content (platform-aware)', () async {
    final content = 'hello-export';
    if (kIsWeb) {
      // On web we exercise the web implementation to ensure it doesn't throw
      // when invoked under the web test runner.
      await export_utils.saveExport('export_test_output.json', content);
      // Can't assert a filesystem write on web; success is lack of exception.
      expect(true, isTrue);
    } else {
      final tmpDir = Directory.systemTemp.createTempSync('sm_save_export_');
      final outPath = '${tmpDir.path}/export_test_output.json';

      await export_utils.saveExport(outPath, content);

      final f = File(outPath);
      expect(f.existsSync(), isTrue);
      final read = await f.readAsString();
      expect(read, equals(content));

      tmpDir.deleteSync(recursive: true);
    }
  });
}
