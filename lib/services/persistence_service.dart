import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../models/shooter.dart';
import '../models/match_stage.dart';
import '../models/stage_result.dart';

/// Service for data persistence using SharedPreferences.
/// Data schema version. Increment this when making breaking changes to persisted data.
const int kDataSchemaVersion = 2; // Incremented schema version
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

  /// Loads and migrates data if needed. Call this on app startup before loading any lists.
  Future<void> ensureSchemaUpToDate() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
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
          (m) => Shooter(
            name: m['name'] as String,
            scaleFactor: (m['scaleFactor'] as num?)?.toDouble() ?? 1.0,
          ),
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

  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
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
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    await ensureSchemaUpToDate();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _logger.info('Attempting to load list from key $key');
    final jsonStr = prefs.getString(key);
    _logger.info('Raw JSON string retrieved for key $key: $jsonStr');
    if (jsonStr == null) {
      _logger.warning('No data found for key $key. Returning empty list.');
      return [];
    }
    final decoded = jsonDecode(jsonStr) as List;
    _logger.info('Decoded JSON for key $key: $decoded');
    return decoded.cast<Map<String, dynamic>>();
  }

  // Migration method is public and can be invoked directly in tests.
}
