import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';

void main() {
  group('ShooterSetupViewModel', () {
    test('can instantiate', () {
      final vm = ShooterSetupViewModel(MatchRepository());
      expect(vm, isA<ShooterSetupViewModel>());
    });

    test('addShooter adds a shooter', () {
      final repo = MatchRepository();
      final vm = ShooterSetupViewModel(repo);
      final error = vm.addShooter('Alice', 0.95);
      expect(error, isNull);
      expect(repo.shooters.length, 1);
      expect(repo.shooters.first.name, 'Alice');
  expect(repo.shooters.first.scaleFactor, 0.95);
    });

    test('addShooter fails for duplicate name', () {
      final repo = MatchRepository();
      final vm = ShooterSetupViewModel(repo);
      vm.addShooter('Bob', 1.0);
      final error = vm.addShooter('Bob', 0.9);
      expect(error, isNotNull);
      expect(repo.shooters.length, 1);
    });

  test('addShooter fails for invalid scale', () {
      final repo = MatchRepository();
      final vm = ShooterSetupViewModel(repo);
      final errorLow = vm.addShooter('Charlie', -0.1);
      final errorHigh = vm.addShooter('Charlie', 1.5);
      expect(errorLow, isNotNull);
      expect(errorHigh, isNotNull);
      expect(repo.shooters, isEmpty);
    });

  test('editShooter updates scale', () {
      final repo = MatchRepository();
      final vm = ShooterSetupViewModel(repo);
      vm.addShooter('Dana', 1.0);
      final error = vm.editShooter('Dana', 0.8);
      expect(error, isNull);
  expect(repo.shooters.first.scaleFactor, 0.8);
    });

    test('editShooter fails for missing shooter', () {
      final repo = MatchRepository();
      final vm = ShooterSetupViewModel(repo);
      final error = vm.editShooter('Eve', 0.9);
      expect(error, isNotNull);
    });

    test('removeShooter removes shooter', () {
      final repo = MatchRepository();
      final vm = ShooterSetupViewModel(repo);
      vm.addShooter('Frank', 1.0);
      vm.removeShooter('Frank');
      expect(repo.shooters, isEmpty);
    });
  });
}
