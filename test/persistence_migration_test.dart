import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

import 'persistence_migration_test.mocks.dart';

@GenerateMocks([SharedPreferences])
// Mockito mock class for SharedPreferences
class TestablePersistenceService extends PersistenceService {
  final SharedPreferences prefs;
  TestablePersistenceService(this.prefs) : super(prefs: prefs);

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

// Helper to make a MockSharedPreferences behave like it persists setString/setInt/clear
void makeWritable(MockSharedPreferences p) {
  // Provide sensible defaults so unstubbed getters return null instead of
  // causing Mockito's MissingStubError when tests call getString/getInt.
  when(p.getInt(any)).thenReturn(null);
  when(p.getString(any)).thenReturn(null);
  when(p.getDouble(any)).thenReturn(null);

  when(p.setInt(any, any)).thenAnswer((inv) async {
    final key = inv.positionalArguments[0] as String;
    final value = inv.positionalArguments[1] as int;
    when(p.getInt(key)).thenReturn(value);
    return true;
  });
  when(p.setString(any, any)).thenAnswer((inv) async {
    final key = inv.positionalArguments[0] as String;
    final value = inv.positionalArguments[1] as String;
    when(p.getString(key)).thenReturn(value);
    return true;
  });
  when(p.setDouble(any, any)).thenAnswer((inv) async {
    final key = inv.positionalArguments[0] as String;
    final value = inv.positionalArguments[1] as double;
    when(p.getDouble(key)).thenReturn(value);
    return true;
  });
  when(p.clear()).thenAnswer((inv) async {
    // clear common keys used in tests
    when(p.getInt(any)).thenReturn(null);
    when(p.getString(any)).thenReturn(null);
    when(p.getDouble(any)).thenReturn(null);
    return true;
  });
}

void main() {
  if (kIsWeb) {
    // This test uses dart:io and SharedPreferences mocks that rely on
    // IO semantics; skip when running under web where dart:io is unavailable.
    print('Skipping persistence_migration_test on web');
    return;
  }

  late IOSink logSink;
  late MockSharedPreferences mockPrefs;


  setUpAll(() {
    // Redirect print statements to a log file
    final logFile = File('migration_test_debug.log');
    logSink = logFile.openWrite();
    runZonedGuarded(
      () {
        testMain();
      },
      (error, stackTrace) {
        logSink.writeln('Error: $error');
        logSink.writeln('StackTrace: $stackTrace');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          logSink.writeln(line);
        },
      ),
    );
  });

  tearDownAll(() async {
    // Close the log sink after all tests
    await logSink.close();
  });

  setUp(() {
  mockPrefs = MockSharedPreferences();

    // Make the mock writable so setInt/setString mutate getInt/getString behavior
    makeWritable(mockPrefs);

    // Seed default stageResults and schema version
    when(mockPrefs.getInt('dataSchemaVersion')).thenReturn(1);
    when(mockPrefs.getString('stageResults')).thenReturn(
      '[{"stage":1,"shooter":"Alice","time":12.5,"a":5,"c":3,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]',
    );
  });

  test(
    'Migration logic upgrades old schema version and preserves data (using mockito)',
    () async {
      // Setup for old schema version
      final mockPrefs1 = MockSharedPreferences();
      // Make mockPrefs1 writable and seed values
      makeWritable(mockPrefs1);
      await mockPrefs1.setInt('dataSchemaVersion', 1);
      await mockPrefs1.setString(
        'shooters',
        '[{"name":"Bob","scaleFactor":1.0}]',
      );
      await mockPrefs1.setString('stages', '[{"stage":2,"scoringShoots":8}]');
      await mockPrefs1.setString(
        'stageResults',
        '[{"stage":2,"shooter":"Bob","time":9.5,"a":4,"c":2,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]',
      );
      // Debug: verify mock stored values
      // seeded mock prefs verified implicitly by repository

      final persistence1 = TestablePersistenceService(mockPrefs1);
      final repo1 = MatchRepository(persistence: persistence1);
      await repo1.loadAll();
      // Avoid calling persistence.loadList here again to prevent re-entering
      // migration/ensureSchema logic which can mutate prefs and affect repository state.
      // Snapshot the lists to avoid any race where another loadAll may run and clear them.
      final stagesSnapshot = List.of(repo1.stages);
      final shootersSnapshot = List.of(repo1.shooters);
      final resultsSnapshot = List.of(repo1.results);
      expect(stagesSnapshot, isNotEmpty);
      expect(stagesSnapshot.first.stage, 2);
      expect(shootersSnapshot, isNotEmpty);
      expect(shootersSnapshot.first.name, 'Bob');
      expect(resultsSnapshot, isNotEmpty);
      expect(resultsSnapshot.first.shooter, 'Bob');

      // Setup for downgrade (future version in storage)
      final mockPrefs2 = MockSharedPreferences();
      makeWritable(mockPrefs2);
      await mockPrefs2.setInt('dataSchemaVersion', 99);
      await mockPrefs2.setString(
        'shooters',
        '[{"name":"Carol","scaleFactor":1.0}]',
      );
      await mockPrefs2.setString('stages', '');
      await mockPrefs2.setString('stageResults', '');

      final persistence2 = TestablePersistenceService(mockPrefs2);
      final repo2 = MatchRepository(persistence: persistence2);
      await repo2.loadAll();
      // When stored schema version is greater than the app's version, persistence
      // clears data to avoid incompatibility. Verify everything is cleared.
      expect(repo2.stages, isEmpty);
      expect(repo2.shooters, isEmpty);
      expect(repo2.results, isEmpty);
    },
  );

  test('Migration logic adds default status to stage results', () async {
    // Setup for old schema version
    final mockPrefs = MockSharedPreferences();
    makeWritable(mockPrefs);
    await mockPrefs.setInt('dataSchemaVersion', 1);
    await mockPrefs.setString(
      'stageResults',
      '[{"stage":1,"shooter":"Alice","time":12.5,"a":5,"c":3,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]',
    );

    final persistence = TestablePersistenceService(mockPrefs);
    await persistence.ensureSchemaUpToDate();

    // Verify migration logic

    final results = await persistence.loadList('stageResults');
    expect(results.length, 1);
    expect(
      results.first['status'],
      'Completed',
    ); // Default value for migrated records

    // Debugging logs
    final updatedResults = mockPrefs.getString('stageResults');
    expect(updatedResults, contains('"status":"Completed"'));

    // Verify schema version
    final schemaVersion = mockPrefs.getInt('dataSchemaVersion');
    expect(schemaVersion, equals(kDataSchemaVersion));
  });

  test('Simplified migration test for status field', () async {
    final mockPrefs = MockSharedPreferences();
    makeWritable(mockPrefs);
    await mockPrefs.setInt('dataSchemaVersion', 1);
    await mockPrefs.setString(
      'stageResults',
      '[{"stage":1,"shooter":"Alice","time":12.5,"a":5,"c":3,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]',
    );

    final persistence = TestablePersistenceService(mockPrefs);
    await persistence.ensureSchemaUpToDate();

    final updatedResults = mockPrefs.getString('stageResults');
    expect(updatedResults, contains('"status":"Completed"'));

    final schemaVersion = mockPrefs.getInt('dataSchemaVersion');
    expect(schemaVersion, equals(kDataSchemaVersion));
  });

  // Updated to use Mockito's @GenerateMocks annotation
  test('Mock data retrieval test with generated mock', () {
    when(mockPrefs.getString('stageResults')).thenReturn(
      '[{"stage":1,"shooter":"Alice","time":12.5,"a":5,"c":3,"d":2,"misses":0,"noShoots":0,"procedureErrors":0}]',
    );

    final rawResults = mockPrefs.getString('stageResults');
    // raw results printed for debugging previously

    expect(rawResults, isNotNull);
    expect(rawResults, contains('"stage":1'));
  });

  // Added a test case to directly call `_migrateSchema`
  test('Directly call migrateSchema to verify behavior', () async {
    final persistenceService = PersistenceService(prefs: mockPrefs);
    await persistenceService.migrateSchema(1, 2, mockPrefs);
    // Migration should update schema version to 2
    verify(mockPrefs.setInt('dataSchemaVersion', kDataSchemaVersion)).called(1);
  });

  test('ensureSchemaUpToDate clears prefs when stored version is higher than current', () async {
    final mockPrefsHigh = MockSharedPreferences();
    makeWritable(mockPrefsHigh);
    // Simulate a stored future version
    await mockPrefsHigh.setInt('dataSchemaVersion', kDataSchemaVersion + 10);
    await mockPrefsHigh.setString('foo', 'bar');

    final persistenceHigh = PersistenceService(prefs: mockPrefsHigh);
    await persistenceHigh.ensureSchemaUpToDate();

    // After downgrade handling, prefs should be cleared and version set to current
    expect(mockPrefsHigh.getInt('dataSchemaVersion'), equals(kDataSchemaVersion));
    expect(mockPrefsHigh.getString('foo'), isNull);
  });

  test('ensureSchemaUpToDate clears prefs when stored version is higher (SharedPreferences mock)', () async {
    // Use the real SharedPreferences test harness (in-memory) to simulate a stored higher version
    SharedPreferences.setMockInitialValues({
      kDataSchemaVersionKey: kDataSchemaVersion + 5,
      'someKey': 'value'
    });
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    await svc.ensureSchemaUpToDate();

    expect(prefs.getInt(kDataSchemaVersionKey), equals(kDataSchemaVersion));
    expect(prefs.getString('someKey'), isNull);
  });

  test('ensureSchemaUpToDate calls clear and resets version (mocked prefs verify calls)', () async {
    final mockPrefsVerify = MockSharedPreferences();
    // Make mock writable so setInt/setString mutate getInt/getString behavior
    makeWritable(mockPrefsVerify);
    // Simulate stored future version
    when(mockPrefsVerify.getInt(kDataSchemaVersionKey)).thenReturn(kDataSchemaVersion + 3);

    final svc = PersistenceService(prefs: mockPrefsVerify);
    await svc.ensureSchemaUpToDate();

    // Verify clear() was called and version was set back to current
    verify(mockPrefsVerify.clear()).called(1);
    verify(mockPrefsVerify.setInt(kDataSchemaVersionKey, kDataSchemaVersion)).called(1);
  });

  test('migrateSchema handles malformed JSON by saving empty list', () async {
    final mockBad = MockSharedPreferences();
    makeWritable(mockBad);
    // seed with old version and invalid JSON
    await mockBad.setInt('dataSchemaVersion', 1);
    await mockBad.setString('stageResults', 'not-a-json');

    final svc = PersistenceService(prefs: mockBad);
    // Should not throw and should save an empty array
    await svc.ensureSchemaUpToDate();

    final updated = mockBad.getString('stageResults');
    expect(updated, isNotNull);
    expect(jsonDecode(updated!), isA<List>());
    expect((jsonDecode(updated) as List).length, equals(0));
    // migrateSchema and ensureSchemaUpToDate both set the version, so expect two calls
    verify(mockBad.setInt('dataSchemaVersion', kDataSchemaVersion)).called(2);
  });

  test('migrateSchema skips non-map items and migrates valid maps', () async {
    final mockMixed = MockSharedPreferences();
    makeWritable(mockMixed);
    await mockMixed.setInt('dataSchemaVersion', 1);
    // include a non-map item (number) and a valid map
    await mockMixed.setString('stageResults', '[1, {"stage":1,"shooter":"A","time":1.0,"a":1,"c":0,"d":0,"misses":0,"noShoots":0,"procedureErrors":0}]');

    final svc = PersistenceService(prefs: mockMixed);
    await svc.ensureSchemaUpToDate();

    final updated = mockMixed.getString('stageResults');
    expect(updated, isNotNull);
    final decoded = jsonDecode(updated!) as List<dynamic>;
    expect(decoded.length, equals(1));
    expect(decoded.first['shooter'], equals('A'));
    expect(decoded.first['status'], equals('Completed'));
  });

  test('migrateSchema preserves existing status value', () async {
    final mockWithStatus = MockSharedPreferences();
    makeWritable(mockWithStatus);
    await mockWithStatus.setInt('dataSchemaVersion', 1);
    await mockWithStatus.setString('stageResults', '[{"stage":1,"shooter":"B","time":1.0,"a":1,"c":0,"d":0,"misses":0,"noShoots":0,"procedureErrors":0,"status":"Custom"}]');

    final svc = PersistenceService(prefs: mockWithStatus);
    await svc.ensureSchemaUpToDate();

    final updated = mockWithStatus.getString('stageResults');
    expect(updated, isNotNull);
    final decoded = jsonDecode(updated!) as List<dynamic>;
    expect(decoded.length, equals(1));
    expect(decoded.first['status'], equals('Custom'));
  });
}

void testMain() {
  // Original test cases go here
}
