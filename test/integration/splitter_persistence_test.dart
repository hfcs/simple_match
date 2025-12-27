import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  group('Splitter persistence', () {
    test('loads saved value from prefs', () async {
      SharedPreferences.setMockInitialValues({'stage_input_fraction_v1': 0.42, 'dataSchemaVersion': 3});
      final prefs = await SharedPreferences.getInstance();
      final svc = PersistenceService(prefs: prefs);
      final v = await svc.getInputFraction();
      expect(v, isNotNull);
      expect(v, closeTo(0.42, 0.0001));
    });

    test('migration sets default when missing and version older', () async {
      // simulate old schema version without splitter key
      SharedPreferences.setMockInitialValues({'dataSchemaVersion': 1});
      final prefs = await SharedPreferences.getInstance();
      final svc = PersistenceService(prefs: prefs);
      await svc.ensureSchemaUpToDate();
      final v = prefs.getDouble(PersistenceService.kInputFractionKey);
      expect(v, isNotNull);
      expect(v, closeTo(2.0 / 3.0, 0.0001));
    });
  });
}
