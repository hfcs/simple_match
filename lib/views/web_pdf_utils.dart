import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;

class WebPdfUtils {
  static Future<void> downloadPdf(pw.Document pdf) async {
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = '_self'
      ..download = 'overall_results.pdf';
    html.document.body?.append(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
