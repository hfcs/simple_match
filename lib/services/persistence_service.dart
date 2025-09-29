import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shooter.dart';
import '../models/match_stage.dart';
import '../models/stage_result.dart';

/// Service for data persistence using SharedPreferences.
/// Data schema version. Increment this when making breaking changes to persisted data.
const int kDataSchemaVersion = 1;
const String kDataSchemaVersionKey = 'dataSchemaVersion';


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
    if (storedVersionRaw == null) {
      await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion);
    } else if (storedVersion < kDataSchemaVersion) {
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
    // Example: if (from < 2 && to >= 2) { ... }
    // For v1, nothing to do.
    // Add migration steps here for future versions.
  }
  // Add loader for shooters
  Future<List<Shooter>> loadShooters() async {
    final list = await loadList('shooters');
    return list.map((m) => Shooter(
      name: m['name'] as String,
      scaleFactor: (m['scaleFactor'] as num?)?.toDouble() ?? 1.0,
    )).toList();
  }

  // Add loader for stages
  Future<List<MatchStage>> loadStages() async {
    final list = await loadList('stages');
    return list.map((m) => MatchStage(
      stage: m['stage'] as int,
      scoringShoots: m['scoringShoots'] as int,
    )).toList();
  }

  // Add loader for stage results
  Future<List<StageResult>> loadStageResults() async {
    final list = await loadList('stageResults');
    return list.map((m) => StageResult(
      stage: m['stage'] as int,
      shooter: m['shooter'] as String,
      time: (m['time'] as num?)?.toDouble() ?? 0.0,
      a: m['a'] as int? ?? 0,
      c: m['c'] as int? ?? 0,
      d: m['d'] as int? ?? 0,
      misses: m['misses'] as int? ?? 0,
      noShoots: m['noShoots'] as int? ?? 0,
      procedureErrors: m['procedureErrors'] as int? ?? 0,
    )).toList();
  }
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
    await prefs.setInt(kDataSchemaVersionKey, kDataSchemaVersion); // Always update version on save
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    await ensureSchemaUpToDate();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.cast<Map<String, dynamic>>();
  }
}
