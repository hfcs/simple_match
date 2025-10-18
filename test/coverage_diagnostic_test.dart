import 'package:flutter_test/flutter_test.dart';

import 'package:simple_match/views/export_utils_io.dart' as export_io;
import 'package:simple_match/views/io_file_helpers_io.dart' as io_helpers;
import 'package:simple_match/views/non_web_pdf_utils.dart' as pdf_utils;

void main() {
  test('coverage diagnostic: capture stack frames for helper files', () async {
    // Call functions that will throw or produce stack frames so we can
    // inspect the stack and check which file paths/line numbers the VM
    // associates with each frame.

    try {
      // read a non-existent file to trigger an exception from readFileBytes
      await io_helpers.readFileBytes('/no/such/path/hopefully_nonexistent');
    } catch (e, st) {
      print('readFileBytes stack:\n$st');
    }

    try {
      // call the PDF download which throws an UnsupportedError
      await pdf_utils.WebPdfUtils.downloadPdf(null as dynamic);
    } catch (e, st) {
      print('downloadPdf stack:\n$st');
    }

    // call saveExport with an invalid directory to force an IO exception
    try {
      await export_io.saveExport('/no/such/dir/test.txt', 'x');
    } catch (e, st) {
      print('saveExport stack:\n$st');
    }

    // If we've reached here, the diagnostic printed the stacks.
    expect(true, isTrue);
  });
}
