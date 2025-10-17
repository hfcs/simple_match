import 'dart:io';

Future<void> saveExport(String path, String content) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsString(content);
}
