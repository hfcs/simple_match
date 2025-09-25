import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for data persistence using SharedPreferences.
class PersistenceService {
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
