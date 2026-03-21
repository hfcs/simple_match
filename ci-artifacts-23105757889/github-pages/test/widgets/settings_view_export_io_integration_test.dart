import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  test('Export Backup JSON generation (non-override IO path)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);
    await repo.loadAll();

    final json = await svc.exportBackupJson();
    expect(json, contains('stages'));
    expect(json, contains('shooters'));
    expect(json, contains('stageResults'));
  });
}
