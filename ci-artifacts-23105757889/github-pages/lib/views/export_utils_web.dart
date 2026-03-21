// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// Web implementation: trigger browser download for the given string content
import 'dart:convert';
import 'dart:html' as html;

Future<void> saveExport(String filename, String content) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = filename;
  html.document.body?.append(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
