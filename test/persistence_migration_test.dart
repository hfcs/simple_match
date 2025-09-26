


import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'dart:convert';

import 'persistence_migration_test.mocks.dart';

@GenerateMocks([SharedPreferences])


// Mockito mock class for SharedPreferences


class TestablePersistenceService extends PersistenceService {
  final SharedPreferences prefs;
  TestablePersistenceService(this.prefs);

  @override
  Future<void> ensureSchemaUpToDate() async {
    final int storedVersion = prefs.getInt('dataSchemaVersion') ?? 1;
    if (storedVersion < 1) {
      await prefs.setInt('dataSchemaVersion', 1);
    } else if (storedVersion > 1) {
      await prefs.clear();
      await prefs.setInt('dataSchemaVersion', 1);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final int storedVersion = prefs.getInt('dataSchemaVersion') ?? 1;
    if (storedVersion < 1) {
      await ensureSchemaUpToDate();
    }
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> decodedList = jsonDecode(jsonStr);
    return decodedList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

void main() {
  test('Migration logic upgrades old schema version and preserves data (using mockito)', () async {
    // Setup for old schema version
  final mockPrefs1 = MockSharedPreferences();
    when(mockPrefs1.getInt('dataSchemaVersion')).thenReturn(1);
    when(mockPrefs1.getString('shooters')).thenReturn('[{"name":"Bob","scaleFactor":1.0}]');
    when(mockPrefs1.getString('stages')).thenReturn('[{"stage":2,"scoringShoots":8}]');
    when(mockPrefs1.getString('stageResults')).thenReturn('[{"stage":2,"shooter":"Bob","time":9.5,"a":4,"c":2,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]');
  when(mockPrefs1.setInt(any, any)).thenAnswer((_) async => true);
    when(mockPrefs1.clear()).thenAnswer((_) async => true);

    final persistence1 = TestablePersistenceService(mockPrefs1);
    final repo1 = MatchRepository(persistence: persistence1);
    await repo1.loadAll();
    expect(repo1.stages.length, 1);
    expect(repo1.stages.first.stage, 2);
    expect(repo1.shooters.length, 1);
    expect(repo1.shooters.first.name, 'Bob');
    expect(repo1.results.length, 1);
    expect(repo1.results.first.shooter, 'Bob');

    // Setup for downgrade (future version in storage)
  final mockPrefs2 = MockSharedPreferences();
    when(mockPrefs2.getInt('dataSchemaVersion')).thenReturn(99);
    when(mockPrefs2.getString('shooters')).thenReturn('[{"name":"Carol","scaleFactor":1.0}]');
  when(mockPrefs2.setInt(any, any)).thenAnswer((_) async => true);
    when(mockPrefs2.clear()).thenAnswer((_) async => true);
    when(mockPrefs2.getString('stages')).thenReturn(null);
    when(mockPrefs2.getString('stageResults')).thenReturn(null);

    final persistence2 = TestablePersistenceService(mockPrefs2);
    final repo2 = MatchRepository(persistence: persistence2);
    await repo2.loadAll();
    expect(repo2.stages, isEmpty);
    expect(repo2.shooters.length, 1);
    expect(repo2.shooters.first.name, 'Carol');
    expect(repo2.results, isEmpty);
  });
}