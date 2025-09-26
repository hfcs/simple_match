import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shooter.dart';
import '../models/match_stage.dart';
import '../models/stage_result.dart';

/// Service for data persistence using SharedPreferences.
class PersistenceService {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.cast<Map<String, dynamic>>();
  }
}
