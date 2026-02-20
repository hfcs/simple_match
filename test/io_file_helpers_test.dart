import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/io_file_helpers_io.dart' as io_helpers;

void main() {
  test('listBackups filters and sorts json files', () async {
    final tmp = await Directory.systemTemp.createTemp('sm_test_io');
    try {
      final f1 = File('${tmp.path}/a.json');
      final f2 = File('${tmp.path}/b.txt');
      final f3 = File('${tmp.path}/c.json');
      await f1.writeAsString('{"k":1}');
      await Future.delayed(Duration(milliseconds: 10));
      await f3.writeAsString('{"k":3}');
      final list = await io_helpers.listBackups(directory: tmp);
      // expect only json files
      expect(list.every((e) => e.path.endsWith('.json')), isTrue);
      // newest first
      expect(list.first.path.endsWith('c.json'), isTrue);
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('readFileBytes returns correct bytes', () async {
    final tmp = await Directory.systemTemp.createTemp('sm_test_io');
    try {
      final f = File('${tmp.path}/data.json');
      final bytes = Uint8List.fromList([1,2,3,4,5]);
      await f.writeAsBytes(bytes);
      final got = await io_helpers.readFileBytes(f.path);
      expect(got, equals(bytes));
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
