import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/export_utils_web.dart' if (dart.library.io) 'package:simple_match/views/export_utils_io.dart' as export_utils;

void main() {
  test('saveExport writes content to file (platform-aware)', () async {
    final content = 'hello-export';
    if (kIsWeb) {
      await export_utils.saveExport('test_export.txt', content);
      expect(true, isTrue);
    } else {
      final dir = Directory.systemTemp.createTempSync('simple_match_test');
      final path = '${dir.path}/out/test_export.txt';

      await export_utils.saveExport(path, content);

      final f = File(path);
      expect(await f.exists(), isTrue);
      expect(await f.readAsString(), equals(content));

      await dir.delete(recursive: true);
    }
  });
}
