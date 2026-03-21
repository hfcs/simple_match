import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:simple_match/views/non_web_pdf_utils.dart';

void main() {
  test('WebPdfUtils.downloadPdf throws on non-web', () async {
    final doc = pw.Document();
    expect(() => WebPdfUtils.downloadPdf(doc), throwsA(isA<UnsupportedError>()));
  });
}
