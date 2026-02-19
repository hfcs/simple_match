import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  test('migrate to v4 adds createdAt and updatedAt in ISO8601 UTC', () async {
    // Prepare mock prefs with an older schema (v3) and records missing timestamps
    SharedPreferences.setMockInitialValues({
      'dataSchemaVersion': 3,
      'stages': jsonEncode([
        {'stage': 1, 'scoringShoots': 5},
        {'stage': 2, 'scoringShoots': 6}
      ]),
      'shooters': jsonEncode([
        {'name': 'Alice', 'scaleFactor': 1.0, 'classificationScore': 100.0}
      ]),
      'stageResults': jsonEncode([
        {
          'stage': 1,
          'shooter': 'Alice',
          'time': 12.5,
          'a': 5,
          'c': 0,
          'd': 0,
          'misses': 0,
          'noShoots': 0,
          'procedureErrors': 0
        }
      ]),
      'teamGame': jsonEncode({'mode': 'off', 'topCount': 0, 'teams': []}),
    });

    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // Run migration
    await svc.ensureSchemaUpToDate();

    // Schema version updated
    expect(prefs.getInt(kDataSchemaVersionKey), equals(kDataSchemaVersion));

    // Stages now include createdAt/updatedAt
    final stagesRaw = prefs.getString('stages');
    expect(stagesRaw, isNotNull);
    final stages = jsonDecode(stagesRaw!) as List;
    for (final s in stages) {
      final map = Map<String, dynamic>.from(s as Map);
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
      final created = DateTime.parse(map['createdAt'] as String);
      expect(created.isUtc, isTrue);
    }

    // Shooters include createdAt/updatedAt
    final shootersRaw = prefs.getString('shooters');
    expect(shootersRaw, isNotNull);
    final shooters = jsonDecode(shootersRaw!) as List;
    final shooterMap = Map<String, dynamic>.from(shooters.first as Map);
    expect(shooterMap['createdAt'], isNotNull);
    expect(shooterMap['updatedAt'], isNotNull);

    // Stage results include createdAt/updatedAt
    final resultsRaw = prefs.getString('stageResults');
    expect(resultsRaw, isNotNull);
    final results = jsonDecode(resultsRaw!) as List;
    final resultMap = Map<String, dynamic>.from(results.first as Map);
    expect(resultMap['createdAt'], isNotNull);
    expect(resultMap['updatedAt'], isNotNull);
  });
}
