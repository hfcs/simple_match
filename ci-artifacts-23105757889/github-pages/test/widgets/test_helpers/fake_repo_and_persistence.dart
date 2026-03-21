import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:simple_match/services/persistence_service.dart';

/// FakePersistence overrides only the methods SettingsView calls in tests.
class FakeImportResult extends ImportResult {
  FakeImportResult({required super.success, super.message, super.counts});
}

class FakePersistence extends PersistenceService {
  final String? exportJsonValue;
  final Future<ImportResult> Function(Uint8List bytes, {bool dryRun, bool backupBeforeRestore})? importFn;

  FakePersistence({this.exportJsonValue, this.importFn});

  @override
  Future<String> exportBackupJson() async {
    print('FakePersistence.exportBackupJson called');
    final v = exportJsonValue ?? '{}';
    print('FakePersistence.exportBackupJson returning length=${v.length}');
    return v;
  }

  @override
  Future<File> exportBackupToFile(String path) async {
    // For tests we write a small temp file to satisfy callers when running on
    // native platforms. On web (kIsWeb) dart:io is unavailable so throw to
    // indicate the caller should use exportBackupJson or a test-provided
    // saveExportOverride instead.
    print('FakePersistence.exportBackupToFile called with path: $path');
    if (kIsWeb) {
      throw UnsupportedError('exportBackupToFile is not supported on web in tests');
    }
    final file = File(path);
    print('FakePersistence: creating file (sync)');
    file.parent.createSync(recursive: true);
    print('FakePersistence: writing file (sync)');
    file.writeAsStringSync(exportJsonValue ?? '{}');
    print('FakePersistence: write complete (sync)');
    return file;
  }

  @override
  Future<ImportResult> importBackupFromBytes(Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = false}) async {
    print('FakePersistence.importBackupFromBytes called dryRun=$dryRun backupBeforeRestore=$backupBeforeRestore bytesLen=${bytes.length}');
    if (importFn != null) {
      print('FakePersistence: delegating to importFn');
      return await importFn!(bytes, dryRun: dryRun, backupBeforeRestore: backupBeforeRestore);
    }
    if (dryRun) {
      print('FakePersistence: returning dryRun success');
      return ImportResult(success: true, counts: {'stages': 0, 'shooters': 0, 'stageResults': 0});
    }
    print('FakePersistence: returning full import success');
    return ImportResult(success: true);
  }

  // Avoid touching SharedPreferences in tests: provide no-op implementations
  @override
  Future<void> ensureSchemaUpToDate() async => Future.value();

  @override
  Future<List<Map<String, dynamic>>> loadList(String key) async => [];

  @override
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async => Future.value();

  @override
  Future<void> saveTeamGame(Map<String, dynamic> map) async => Future.value();

  @override
  Future<Map<String, dynamic>?> loadTeamGame() async => null;
}
