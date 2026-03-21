import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/services/persistence_service.dart';

void main() {
  test('migrateSchema adds default status and roRemark and updates schema version',
      () async {
    // Pre-v2 data: stageResults entries without 'status' or 'roRemark'
    final original = [
      {
        'stage': 1,
        'shooter': 'Bob',
        'time': 12.34,
        'a': 2,
        'c': 1,
        'd': 0,
        'misses': 0,
        'noShoots': 0,
        'procedureErrors': 0,
      }
    ];

    SharedPreferences.setMockInitialValues({
      'stageResults': jsonEncode(original),
      // explicitly set old schema version to 0 to force migration
      kDataSchemaVersionKey: 0,
    });

    final prefs = await SharedPreferences.getInstance();
    final persistence = PersistenceService(prefs: prefs);

    // ensureSchemaUpToDate will invoke migrateSchema when needed
    await persistence.ensureSchemaUpToDate();

    final storedJson = prefs.getString('stageResults');
    expect(storedJson, isNotNull);

    final decoded = jsonDecode(storedJson!) as List<dynamic>;
    expect(decoded, isNotEmpty);

    final first = decoded.first as Map<String, dynamic>;
    expect(first['status'], equals('Completed'));
    expect(first['roRemark'], equals(''));
    expect(prefs.getInt(kDataSchemaVersionKey), equals(kDataSchemaVersion));
  });
}
