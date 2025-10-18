import 'package:pdf/widgets.dart' as pw;

class WebPdfUtils {
  static Future<void> downloadPdf(pw.Document pdf) async {
    // Non-web platforms do not support direct downloads.
    throw UnsupportedError('PDF download is not supported on this platform.');
  }
}

// (No test markers remain)
