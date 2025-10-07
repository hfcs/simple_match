import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/services/persistence_service.dart';

class MockPersistenceService extends PersistenceService {
  @override
  Future<List<Shooter>> loadShooters() async => [
    Shooter(name: 'Test', scaleFactor: 1.0),
  ];
}

void main() {
  test('ShooterSetupViewModel edge cases', () {
    final repo = MatchRepository(
      persistence: MockPersistenceService(),
      initialStages: [],
      initialShooters: [Shooter(name: 'Test', scaleFactor: 1.0)],
    );
    final vm = ShooterSetupViewModel(repo);
    // Try to add duplicate shooter
    final result = vm.addShooter('Test', 1.0);
    expect(result, isNotNull);
    // Try to add invalid scale factor
    final result2 = vm.addShooter('NewShooter', -1.0);
    expect(result2, isNotNull);
  });
}
