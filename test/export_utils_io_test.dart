import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/export_utils_io.dart';

void main() {
  test('saveExport writes content to file', () async {
    final dir = Directory.systemTemp.createTempSync('simple_match_test');
    final path = '${dir.path}/out/test_export.txt';
    final content = 'hello-export';

    await saveExport(path, content);

    final f = File(path);
    expect(await f.exists(), isTrue);
    expect(await f.readAsString(), equals(content));

    await dir.delete(recursive: true);
  });
}
