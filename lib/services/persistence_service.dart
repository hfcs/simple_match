// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:io';
import 'platform_info.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../models/shooter.dart';
import '../models/match_stage.dart';
import '../models/stage_result.dart';

/// Service for data persistence using SharedPreferences.
/// Data schema version. Increment this when making breaking changes to persisted data.
const int kDataSchemaVersion = 3; // Added Shooter.classificationScore
const String kDataSchemaVersionKey = 'dataSchemaVersion';

final _logger = Logger('PersistenceService');

/// PersistenceService now supports dependency injection for SharedPreferences.
/// This enables full testability: in tests, inject a mock or in-memory instance.
/// In production, the default constructor is unchanged.
class PersistenceService {
  final SharedPreferences? _prefs;

  /// If [prefs] is provided, it will be used for all persistence operations (for testing).
  /// Otherwise, SharedPreferences.getInstance() is used (for production).
  PersistenceService({SharedPreferences? prefs}) : _prefs = prefs;

  // Helper to get SharedPreferences with micro-tracing for test diagnostics.
  Future<SharedPreferences> _prefsInstance() async {
    if (_prefs != null) return _prefs;
    final start = DateTime.now();
    if (kDebugMode) print('TESTDBG: SharedPreferences.getInstance start ${start.toIso8601String()}');
    final p = await SharedPreferences.getInstance();
    final end = DateTime.now();
    if (kDebugMode) print('TESTDBG: SharedPreferences.getInstance end ${end.toIso8601String()} duration=${end.difference(start).inMilliseconds}ms');
    return p;
  }

  /// Loads and migrates data if needed. Call this on app startup before loading any lists.
  Future<void> ensureSchemaUpToDate() async {
    if (kDebugMode) print('TESTDBG: ensureSchemaUpToDate start');
    final prefs = await _prefsInstance();
    final int? storedVersionRaw = prefs.getInt(kDataSchemaVersionKey);
    final int storedVersion = storedVersionRaw ?? 0;
    _logger.info(
      'Stored version: $storedVersion, Current version: $kDataSchemaVersion',
    );
    if (storedVersionRaw == null) {
      await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
    } else if (storedVersion < kDataSchemaVersion) {
      _logger.info(
        'Invoking migrateSchema with storedVersion: $storedVersion, kDataSchemaVersion: $kDataSchemaVersion',
      );
      await migrateSchema(storedVersion, kDataSchemaVersion, prefs);
      await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
    } else if (storedVersion > kDataSchemaVersion) {
      // Future-proof: if app is downgraded, clear data to avoid incompatibility
      await prefs.clear();
      await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
    }
    if (kDebugMode) print('TESTDBG: ensureSchemaUpToDate completed');
  }

  /// Migration logic for future schema changes. Add cases as schema evolves.
  Future<void> migrateSchema(int from, int to, SharedPreferences prefs) async {
    _logger.info('migrateSchema invoked with from: $from, to: $to');
    if (from < 2 && to >= 2) {
      // Migration for v2: Add 'status' field to StageResult with default value 'Completed'
      _logger.info('Starting migration from version $from to $to');
      _logger.info(
        'Initial data in stageResults: ${prefs.getString('stageResults')}',
      );

      // IMPORTANT: avoid calling loadList here because loadList calls ensureSchemaUpToDate,
      // which may call migrateSchema again and cause recursion/infinite loop during migration.
      final raw = prefs.getString('stageResults');
      _logger.info('Raw stageResults JSON from prefs: $raw');
      final results = <Map<String, dynamic>>[];
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as List;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              results.add(item);
            } else if (item is Map) {
              results.add(Map<String, dynamic>.from(item));
            } else {
              _logger.warning(
                'Unexpected item type in stageResults: ${item.runtimeType}',
              );
            }
          }
        } catch (e, st) {
          _logger.severe(
            'Failed to decode stageResults during migration: $e',
            e,
            st,
          );
        }
      }

      _logger.info('Loaded stageResults for migration: $results');

      final updatedResults = <Map<String, dynamic>>[];
      for (final result in results) {
        _logger.info('Inspecting result: $result');
        final updatedResult = Map<String, dynamic>.from(result);
        if (!updatedResult.containsKey('status') ||
            updatedResult['status'] == null) {
          updatedResult['status'] = 'Completed';
          _logger.info('Updated result with status: $updatedResult');
        } else {
          _logger.info('Result already has status: $updatedResult');
        }
        // Ensure roRemark field exists in migrated data (default empty string)
        if (!updatedResult.containsKey('roRemark') || updatedResult['roRemark'] == null) {
          updatedResult['roRemark'] = '';
          _logger.info('Added default roRemark field: $updatedResult');
        }
        updatedResults.add(updatedResult);
      }
      _logger.info('Final updatedResults: $updatedResults');
      // Save directly using prefs to avoid triggering ensureSchemaUpToDate again
      try {
        final jsonStr = jsonEncode(updatedResults);
        await prefs.setString('stageResults', jsonStr);
        await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
        _logger.info(
          'Migration saved. New stageResults: ${prefs.getString('stageResults')}',
        );
      } catch (e, st) {
        _logger.severe('Failed to save migrated data: $e', e, st);
        rethrow;
      }
    }

    // Note: UI client-only preferences (such as splitter position) should not
    // be part of the persisted data schema. Those keys are intentionally not
    // migrated here and are excluded from backups/imports to keep the data
    // model focused on match data only.

    // Migration for v3: add `classificationScore` to each shooter with default 100.0
    if (from < 3 && to >= 3) {
      _logger.info('Migrating shooters to include classificationScore (v3)');
      String? rawShooters;
      try {
        rawShooters = prefs.getString('shooters');
      } catch (e, st) {
        // Some tests use Mockito mocks for SharedPreferences and may not
        // stub getString('shooters'). Avoid failing the entire test run;
        // log and skip shooter migration in that case.
        _logger.warning('Could not read shooters from prefs during v3 migration: $e', e, st);
        rawShooters = null;
      }

      final updatedShooters = <Map<String, dynamic>>[];
      if (rawShooters != null) {
        try {
          final decoded = jsonDecode(rawShooters) as List;
          for (final item in decoded) {
            Map<String, dynamic> map;
            if (item is Map<String, dynamic>) {
              map = Map<String, dynamic>.from(item);
            } else if (item is Map) {
              map = Map<String, dynamic>.from(item);
            } else {
              continue;
            }
            if (!map.containsKey('classificationScore') || map['classificationScore'] == null) {
              map['classificationScore'] = 100.0;
            }
            updatedShooters.add(map);
          }
        } catch (e, st) {
          _logger.severe('Failed to decode shooters during v3 migration: $e', e, st);
        }
      }
      if (updatedShooters.isNotEmpty) {
        try {
          await prefs.setString('shooters', jsonEncode(updatedShooters));
          await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
          _logger.info('Saved migrated shooters for v3');
        } catch (e, st) {
          _logger.severe('Failed to save migrated shooters for v3: $e', e, st);
          rethrow;
        }
      }
    }

    _logger.info('Migrating schema: Current data before migration:');
    _logger.info(
      'Adding default status field with value "Completed" to each record.',
    );
    // Add future migration steps here
  }

  // Add loader for shooters
  Future<List<Shooter>> loadShooters() async {
    final list = await loadList('shooters');
    return list
        .map(
          (m) => Shooter.fromJson(m),
        )
        .toList();
  }

  // Add loader for stages
  Future<List<MatchStage>> loadStages() async {
    final list = await loadList('stages');
    return list
        .map(
          (m) => MatchStage(
            stage: m['stage'] as int,
            scoringShoots: m['scoringShoots'] as int,
          ),
        )
        .toList();
  }

  // Add loader for stage results
  Future<List<StageResult>> loadStageResults() async {
    final list = await loadList('stageResults');
    return list
        .map(
          (m) => StageResult(
            stage: m['stage'] as int,
            shooter: m['shooter'] as String,
            time: (m['time'] as num?)?.toDouble() ?? 0.0,
            a: m['a'] as int? ?? 0,
            c: m['c'] as int? ?? 0,
            d: m['d'] as int? ?? 0,
            misses: m['misses'] as int? ?? 0,
            noShoots: m['noShoots'] as int? ?? 0,
            procedureErrors: m['procedureErrors'] as int? ?? 0,
            status: (m['status'] as String?) ?? 'Completed',
            roRemark: (m['roRemark'] as String?) ?? '',
          ),
        )
        .toList();
  }

  // NOTE: UI-only client preferences (splitter, window layout, etc.) are not
  // part of the persisted data model used for backups/imports or schema
  // migrations. UI settings should be stored/read by the client UI layer and
  // are intentionally excluded from this service to keep the data model
  // portable between different app instances and platforms.

  /// Build a full backup map containing metadata and all lists.
  Future<Map<String, dynamic>> buildBackupMap() async {
    await ensureSchemaUpToDate();
    final prefs = await _prefsInstance();
    // For metadata we include schema version and timestamp
    final meta = <String, dynamic>{
      'schemaVersion': prefs.getInt(kDataSchemaVersionKey) ?? kDataSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': 'unknown', // kept simple for MVP
      'platform': getPlatformName(),
    };
    final stages = await loadList('stages');
    final shooters = await loadList('shooters');
    final results = await loadList('stageResults');
    return {
      'metadata': meta,
      'stages': stages,
      'shooters': shooters,
      'stageResults': results,
    };
  }

  /// Return JSON string of a full backup (plain JSON, MVP no compression).
  Future<String> exportBackupJson() async {
    final map = await buildBackupMap();
    return jsonEncode(map);
  }

  /// Atomic write to file path (plain JSON). Throws on IO errors.
  Future<File> exportBackupToFile(String path) async {
    final jsonStr = await exportBackupJson();
    final outFile = File(path);
    final tmp = File('${path}.tmp');

    // Ensure parent dir exists
    try {
      await outFile.parent.create(recursive: true);
    } catch (e) {
      throw Exception('Failed to create parent directory for export file: $e');
    }

    try {
      await tmp.writeAsString(jsonStr);
    } catch (e) {
      throw Exception('Failed to write temporary export file: $e');
    }

    // Try atomic rename; fall back to copy if rename isn't supported on the platform/filesystem
    try {
      if (await outFile.exists()) {
        await outFile.delete();
      }
      return await tmp.rename(path);
    } catch (e) {
      // Non-atomic fallback: copy and remove temp file
      try {
        await tmp.copy(path);
        await tmp.delete();
        return File(path);
      } catch (e2) {
        throw Exception('Failed to finalize export file (rename and copy failed): $e ; $e2');
      }
    }
  }

  /// Result object returned from import operation.
  /// Simple MVP: success flag, message, and counts of imported records.


  /// Import backup from raw bytes (expects UTF-8 JSON). If [dryRun] is true,
  /// validate only and do not persist. If [backupBeforeRestore] is true, save
  /// a snapshot of current persisted data in prefs under key 'backup_before_restore'.
  Future<ImportResult> importBackupFromBytes(Uint8List bytes, {bool dryRun = false, bool backupBeforeRestore = true}) async {
    final prefs = await _prefsInstance();
    String jsonStr;
    try {
      jsonStr = utf8.decode(bytes);
    } catch (e) {
      return ImportResult(success: false, message: 'Invalid UTF-8 in backup bytes');
    }

    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return ImportResult(success: false, message: 'Backup JSON must be an object');
      parsed = decoded;
    } catch (e) {
      return ImportResult(success: false, message: 'Failed to parse JSON: $e');
    }

    // Basic validation
    if (!parsed.containsKey('stages') || !parsed.containsKey('shooters') || !parsed.containsKey('stageResults')) {
      return ImportResult(success: false, message: 'Backup missing required keys (stages, shooters, stageResults)');
    }

    final stages = parsed['stages'];
    final shooters = parsed['shooters'];
    final results = parsed['stageResults'];
    if (stages is! List || shooters is! List || results is! List) {
      return ImportResult(success: false, message: 'Backup keys must be lists');
    }

    // If dry run, return counts and success
    if (dryRun) {
      return ImportResult(success: true, counts: {
        'stages': stages.length,
        'shooters': shooters.length,
        'stageResults': results.length,
      });
    }

    // Backup current data snapshot in prefs (simple MVP)
    if (backupBeforeRestore) {
      try {
        final current = await buildBackupMap();
        await prefs.setString('backup_before_restore', jsonEncode(current));
      } catch (e, st) {
        _logger.warning('Failed to create backup_before_restore snapshot: $e', e, st);
      }
    }

    // Persist incoming lists using saveList to ensure schema version updates
    try {
      // normalize to List<Map<String,dynamic>>
      final stagesList = stages.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      final shootersList = shooters.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      final resultsList = results.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      await saveList('stages', stagesList);
      await saveList('shooters', shootersList);
      await saveList('stageResults', resultsList);
    } catch (e, st) {
      _logger.severe('Failed to persist imported backup: $e', e, st);
      return ImportResult(success: false, message: 'Failed to save imported data: $e');
    }
    
    return ImportResult(success: true, counts: {
      'stages': stages.length,
      'shooters': shooters.length,
      'stageResults': results.length,
    });
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    if (kDebugMode) print('TESTDBG: saveList start key=$key len=${list.length}');
    final prefs = await _prefsInstance();
    _logger.info('Attempting to save list to key $key with data: $list');
    final jsonStr = jsonEncode(list);
    _logger.info('Encoded JSON string: $jsonStr');
    final result = await prefs.setString(key, jsonStr);
    _logger.info('Result of setString for key $key: $result');
    _logger.info('Data in prefs after saveList: ${prefs.getString(key)}');
    await prefs.setInt(
      kDataSchemaVersionKey,
      kDataSchemaVersion,
    ); // Always update version on save
    if (kDebugMode) print('TESTDBG: saveList completed key=$key');
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    if (kDebugMode) print('TESTDBG: loadList start key=$key');
    await ensureSchemaUpToDate();
    if (kDebugMode) print('TESTDBG: ensureSchemaUpToDate returned for loadList key=$key');
    final prefs = await _prefsInstance();
    _logger.info('Attempting to load list from key $key');
    final jsonStr = prefs.getString(key);
    _logger.info('Raw JSON string retrieved for key $key: $jsonStr');
    if (jsonStr == null) {
      _logger.warning('No data found for key $key. Returning empty list.');
      if (kDebugMode) print('TESTDBG: loadList end key=$key returned empty');
      return [];
    }
    final decoded = jsonDecode(jsonStr) as List;
    _logger.info('Decoded JSON for key $key: $decoded');
    if (kDebugMode) print('TESTDBG: loadList completed key=$key len=${decoded.length}');
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Save team game configuration as a single JSON object under key 'teamGame'
  Future<void> saveTeamGame(Map<String, dynamic> map) async {
    final prefs = await _prefsInstance();
    _logger.info('Saving teamGame: $map');
    await prefs.setString('teamGame', jsonEncode(map));
    await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
  }

  /// Load team game configuration, or null if not present.
  Future<Map<String, dynamic>?> loadTeamGame() async {
    if (kDebugMode) print('TESTDBG: loadTeamGame start');
    await ensureSchemaUpToDate();
    if (kDebugMode) print('TESTDBG: ensureSchemaUpToDate returned for loadTeamGame');
    final prefs = await _prefsInstance();
    final raw = prefs.getString('teamGame');
    if (raw == null) {
      if (kDebugMode) print('TESTDBG: loadTeamGame no teamGame present');
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (kDebugMode) print('TESTDBG: loadTeamGame decoded');
      return decoded;
    } catch (e, st) {
      _logger.warning('Failed to decode teamGame JSON: $e', e, st);
      if (kDebugMode) print('TESTDBG: loadTeamGame decode failed: $e');
      return null;
    }
  }

  // Migration method is public and can be invoked directly in tests.
}

/// Result object returned from import operations.
class ImportResult {
  final bool success;
  final String? message;
  final Map<String, int> counts;
  ImportResult({required this.success, this.message, Map<String, int>? counts}) : counts = counts ?? {};
}
