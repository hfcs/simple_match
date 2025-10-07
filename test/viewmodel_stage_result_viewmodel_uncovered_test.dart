import 'package:flutter_test/flutter_test.dart';

import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/services/persistence_service.dart';

// Simple mock PersistenceService that returns empty lists
class MockPersistenceService extends PersistenceService {
  @override
  Future<List<Map<String, dynamic>>> loadList(String key) async => [];
  @override
  Future<void> ensureSchemaUpToDate() async {}
}

void main() {
  test('StageResultViewModel edge cases', () async {
    final mockPersistence = MockPersistenceService();
    final vm = StageResultViewModel(persistenceService: mockPersistence);
    // Add a result and test calculation
    vm.results.add(
      StageResult(
        shooter: 'Test',
        stage: 1,
        time: 10.0,
        a: 5,
        c: 2,
        d: 1,
        misses: 0,
        noShoots: 0,
        procedureErrors: 0,
      ),
    );
    expect(vm.results.length, 1);
    // Test edge: getStageRanks with no stages
    expect(vm.getStageRanks(), isEmpty);
    // Test edge: get shooters with no shooters
    final emptyVm = StageResultViewModel(persistenceService: mockPersistence);
    expect(emptyVm.shooters, isEmpty);
  });
}
