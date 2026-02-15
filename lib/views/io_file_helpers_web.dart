// Web shim: no documents directory or file system access. Expose minimal stubs
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, dead_code
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
// `dart:js_util` is only available on web. When analyzing for non-web targets
// the analyzer may report a missing URI. Suppress that specific error here
// because this file is a web-only shim.
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;

Future<dynamic> getDocumentsDirectory() async {
  // No documents dir on web
  return null;
}

Future<List<dynamic>> listBackups() async {
  // Not supported on web
  return <dynamic>[];
}

Future<Uint8List> readFileBytes(String path) async {
  throw UnsupportedError('Reading files from a path is not supported on web');
}

/// Show a browser file picker to let the user choose a backup file.
/// Returns a map with keys 'bytes' (Uint8List) and 'name' (String).
Future<Map<String, dynamic>?> pickBackupFileViaBrowser() async {
  final input = html.FileUploadInputElement();
  input.accept = '.json,application/json';
  input.multiple = false;

  // Inject into document and click
  html.document.body?.append(input);
  final completer = Completer<Map<String, dynamic>?>();

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      input.remove();
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final result = reader.result;
      try {
        Uint8List bytes;
        if (result is ByteBuffer) {
          bytes = Uint8List.view(result);
        } else if (result is Uint8List) {
          bytes = result;
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        } else if (result is String) {
          // Some platforms may return a String; decode as UTF-8
          bytes = Uint8List.fromList(utf8.encode(result));
        } else {
          // Try JS interop: some browsers return a JS TypedArray object that
          // Dart does not automatically map to ByteBuffer/TypedData. Attempt
          // to access its `.buffer` property which should be an ArrayBuffer.
            try {
              final maybeBufferObj = js_util.getProperty(result as Object, 'buffer');
              if (maybeBufferObj is ByteBuffer) {
                bytes = Uint8List.view(maybeBufferObj);
              } else {
                completer.completeError(StateError('Unexpected FileReader result type: ${result.runtimeType}'));
                input.remove();
                return;
              }
            } catch (e) {
              completer.completeError(StateError('Unexpected FileReader result type: ${result.runtimeType}'));
              input.remove();
              return;
            }
        }
        completer.complete({'bytes': bytes, 'name': file.name});
      } catch (e) {
        completer.completeError(StateError('Failed to convert file bytes: $e'));
      } finally {
        input.remove();
      }
    });
    reader.onError.listen((event) {
      // FileReader onError provides an Event; surface a generic error
      completer.completeError(StateError('File read error'));
      input.remove();
    });
  });

  // Trigger the file picker UI
  input.click();
  return completer.future;
}
