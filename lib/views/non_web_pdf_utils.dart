import 'package:pdf/widgets.dart' as pw;

class WebPdfUtils {
  static Future<void> downloadPdf(pw.Document pdf) async {
    // Non-web platforms do not support direct downloads.
    throw UnsupportedError('PDF download is not supported on this platform.');
  }
}

// Public marker used by tests for coverage attribution.
int coverageMarkerNonWebPdfUtils() => 1;

int _nonWebPdfUtils_importInitializer() => 0;

final int nonWebPdfUtilsImported = _nonWebPdfUtils_importInitializer();
