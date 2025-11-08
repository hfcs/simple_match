import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/io_file_helpers_io.dart';

void main() {
  if (kIsWeb) {
    print('Skipping io_file_helpers_io_test on web');
    return;
  }
  test('listBackups returns json files sorted by modified desc and readFileBytes reads', () async {
    final dir = Directory.systemTemp.createTempSync('simple_match_backups');

    final a = File('${dir.path}/one.json')..writeAsStringSync('a');
    await Future.delayed(Duration(milliseconds: 5));
    final b = File('${dir.path}/two.json')..writeAsStringSync('b');

    final files = await listBackups(directory: dir);
    expect(files.map((f) => f.path).toList(), containsAll([a.path, b.path]));
    // newest first
    expect(files.first.path, equals(b.path));

    final bytes = await readFileBytes(a.path);
    expect(bytes, isA<Uint8List>());
    expect(String.fromCharCodes(bytes), equals('a'));

    await dir.delete(recursive: true);
  });
}
