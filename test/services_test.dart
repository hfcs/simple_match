import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  group('PersistenceService', () {
    test('can instantiate', () {
      final service = PersistenceService();
      expect(service, isA<PersistenceService>());
    });
    // TODO: Add tests for read/write logic when implemented
  });
}
