// IO implementation for file helpers
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<Directory> getDocumentsDirectory() => getApplicationDocumentsDirectory();

/// List JSON backup files in the documents directory.
///
/// An optional [directory] may be provided for testing. If omitted the
/// application documents directory will be used.
Future<List<FileSystemEntity>> listBackups({Directory? directory}) async {
  final dir = directory ?? await getDocumentsDirectory();
  final files = dir.listSync().where((f) => f.path.endsWith('.json')).toList();
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files;
}

Future<Uint8List> readFileBytes(String path) async {
  final f = File(path);
  return await f.readAsBytes();
}

/// On non-web platforms this picker is not used; provide a stub so the
/// symbol exists when the file is conditionally imported by SettingsView.
Future<Map<String, dynamic>?> pickBackupFileViaBrowser() async {
  return null;
}
