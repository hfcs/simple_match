import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('Imported timestamps are ISO8601 UTC and parseable', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    final backup = {
      'stages': [],
      'shooters': [
        {
          'name': 'Bob',
          'scaleFactor': 1.0,
          // legacy keys intentionally
          'createdAt': '2020-01-01T00:00:00',
          'updatedAt': '2020-01-02T12:34:56',
        }
      ],
      'stageResults': []
    };

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));
    final res = await svc.importBackupFromBytes(bytes);
    expect(res.success, isTrue);

    final shooters = await svc.loadList('shooters');
    expect(shooters, isNotEmpty);
    final s = shooters.first;
    expect(s.containsKey('createdAtUtc'), isTrue);
    expect(s.containsKey('updatedAtUtc'), isTrue);

    // ensure parseable and treated as UTC
    final created = DateTime.parse(s['createdAtUtc'] as String);
    final updated = DateTime.parse(s['updatedAtUtc'] as String);
    expect(created.isUtc, isTrue);
    expect(updated.isUtc, isTrue);
  });

  test('updatedAtUtc advances when importing an update without timestamps', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    final old = DateTime.now().toUtc().subtract(const Duration(minutes: 5)).toIso8601String();
    // seed initial shooter with an older updatedAtUtc
    await svc.saveList('shooters', [
      {'name': 'Alice', 'scaleFactor': 1.0, 'createdAtUtc': old, 'updatedAtUtc': old}
    ]);

    // import an updated record without timestamps -> service will assign now
    final backup = {
      'stages': [],
      'shooters': [
        {'name': 'Alice', 'scaleFactor': 1.5} // changed scaleFactor
      ],
      'stageResults': []
    };

    final res = await svc.importBackupFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(backup))));
    expect(res.success, isTrue);

    final shooters = await svc.loadList('shooters');
    final a = shooters.singleWhere((m) => m['name'] == 'Alice');
    final updated = DateTime.parse(a['updatedAtUtc'] as String);
    final oldDt = DateTime.parse(old);
    expect(updated.isAfter(oldDt), isTrue);
  });

  test('legacy createdAt/updatedAt in backup map to *_Utc after import', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    final legacyCreated = '2019-05-05T05:05:05';
    final legacyUpdated = '2019-06-06T06:06:06';

    final backup = {
      'stages': [],
      'shooters': [
        {'name': 'Legacy', 'createdAt': legacyCreated, 'updatedAt': legacyUpdated}
      ],
      'stageResults': []
    };

    final res = await svc.importBackupFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(backup))));
    expect(res.success, isTrue);

    final shooters = await svc.loadList('shooters');
    final l = shooters.singleWhere((m) => m['name'] == 'Legacy');
    expect(l['createdAtUtc'], equals(legacyCreated));
    expect(l['updatedAtUtc'], equals(legacyUpdated));
  });

  test('audit logs are appended and timestamps are ordered', () async {
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);

    // initial import: creates one shooter => should produce a create log
    final backup1 = {
      'stages': [],
      'shooters': [
        {'name': 'Loggy'}
      ],
      'stageResults': []
    };
    final r1 = await svc.importBackupFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(backup1))));
    expect(r1.success, isTrue);

    final logs1 = await svc.loadList('shootersLog');
    expect(logs1.length, greaterThanOrEqualTo(1));
    final firstTimestamp = DateTime.parse(logs1.last['timestampUtc'] as String);

    // second import: update the shooter -> should append an update entry
    final backup2 = {
      'stages': [],
      'shooters': [
        {'name': 'Loggy', 'scaleFactor': 2.0}
      ],
      'stageResults': []
    };
    final r2 = await svc.importBackupFromBytes(Uint8List.fromList(utf8.encode(jsonEncode(backup2))));
    expect(r2.success, isTrue);

    final logs2 = await svc.loadList('shootersLog');
    expect(logs2.length, greaterThanOrEqualTo(logs1.length + 1));
    // ensure timestamps are non-decreasing
    DateTime? prev;
    for (final e in logs2) {
      final ts = DateTime.parse(e['timestampUtc'] as String);
      if (prev != null) expect(!ts.isBefore(prev), isTrue);
      prev = ts;
    }
    // last entry should be after or equal to firstTimestamp
    final lastTimestamp = DateTime.parse(logs2.last['timestampUtc'] as String);
    expect(lastTimestamp.isAfter(firstTimestamp) || lastTimestamp.isAtSameMomentAs(firstTimestamp), isTrue);
  });
}
