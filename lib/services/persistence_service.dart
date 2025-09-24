import 'dart:convert';

/// Service for data persistence (e.g., local storage).
class PersistenceService {
  // Simulate persistent storage with a map (replace with SharedPreferences in real app)
  final Map<String, String> _storage = {};

  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    _storage[key] = jsonEncode(list);
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final jsonStr = _storage[key];
    if (jsonStr == null) return [];
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.cast<Map<String, dynamic>>();
  }
}
