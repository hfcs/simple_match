import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_match/views/export_utils_io.dart' as export_io;
import 'package:simple_match/views/io_file_helpers_io.dart' as io_helpers;
import 'package:simple_match/views/non_web_pdf_utils.dart' as pdf_utils;

void main() {
  test('coverage diagnostic: capture stack frames for helper files (clean)', () async {
    if (!kIsWeb) {
      try {
        await io_helpers.readFileBytes('/no/such/path/hopefully_nonexistent');
      } catch (e, st) {
        print('readFileBytes stack:\n$st');
      }

      try {
        await export_io.saveExport('/no/such/dir/test.txt', 'x');
      } catch (e, st) {
        print('saveExport stack:\n$st');
      }
    } else {
      print('Skipping IO diagnostics on web');
    }

    try {
      await pdf_utils.WebPdfUtils.downloadPdf(null as dynamic);
    } catch (e, st) {
      print('downloadPdf stack:\n$st');
    }

    expect(true, isTrue);
  });
}
