import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  group('Persistence backup integration-style', () {
    late PersistenceService svc;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      svc = PersistenceService();
      await svc.ensureSchemaUpToDate();
    });

    test('export to file and import back restores data', () async {
      // Prepare some data by directly saving lists
      await svc.saveList('stages', [ {'stage': 3, 'scoringShoots': 5} ]);
      await svc.saveList('shooters', [ {'name': 'Carla', 'scaleFactor': 0.95} ]);
      await svc.saveList('stageResults', [
        {'stage': 3, 'shooter': 'Carla', 'time': 11.2, 'a': 5, 'c': 0, 'd': 0, 'misses': 0, 'noShoots': 0, 'procedureErrors': 0, 'status': 'Completed', 'roRemark': ''}
      ]);

      final tmpDir = Directory.systemTemp.createTempSync('simple_match_test_');
      final outPath = '${tmpDir.path}/export.json';
      final outFile = await svc.exportBackupToFile(outPath);
      expect(await outFile.exists(), isTrue);

      // Clear prefs to simulate fresh app
      SharedPreferences.setMockInitialValues({});
      svc = PersistenceService();
      await svc.ensureSchemaUpToDate();

      final bytes = await outFile.readAsBytes();
      final res = await svc.importBackupFromBytes(Uint8List.fromList(bytes), dryRun: false);
      expect(res.success, isTrue);

      final stages = await svc.loadStages();
      final shooters = await svc.loadShooters();
      final results = await svc.loadStageResults();

      expect(stages.length, equals(1));
      expect(shooters.length, equals(1));
      expect(results.length, equals(1));

      expect(shooters.first.name, equals('Carla'));

      // Clean up
      try {
        tmpDir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });
}
