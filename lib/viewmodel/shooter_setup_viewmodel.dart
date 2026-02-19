import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repository/match_repository.dart';
import '../models/shooter.dart';

/// ViewModel for shooter setup page.
class ShooterSetupViewModel {
  final MatchRepository repository;
  ShooterSetupViewModel(this.repository);

  /// Adds a shooter. Returns null on success, or error string on failure.
  String? addShooter(String name, double scaleFactor) {
    if (name.trim().isEmpty) return 'Name required.';
    if (scaleFactor < 0.1 || scaleFactor > 20.0) {
      return 'Invalid scale: must be between 0.100 and 20.000.';
    }
    if (repository.shooters.any((s) => s.name == name)) {
      return 'Shooter already exists.';
    }
    try {
      repository.addShooter(Shooter(name: name, scaleFactor: scaleFactor)).catchError((e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('DBG: ShooterSetupViewModel.addShooter background save failed: $e');
        }
      });
    } catch (e) {
      return 'Failed to add shooter: $e';
    }
    return null;
  }

  /// Edits a shooter's scale. Returns null on success, or error string on failure.
  String? editShooter(String name, double scaleFactor) {
    if (scaleFactor < 0.1 || scaleFactor > 20.0) {
      return 'Invalid scale: must be between 0.100 and 20.000.';
    }
    final orig = repository.getShooter(name);
    if (orig == null) return 'Shooter not found.';
    // Preserve classificationScore when editing scale
    try {
      repository.updateShooter(Shooter(
        name: name,
        scaleFactor: scaleFactor,
        classificationScore: orig.classificationScore,
        createdAt: orig.createdAt,
        updatedAt: orig.updatedAt,
      )).catchError((e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('DBG: ShooterSetupViewModel.editShooter background save failed: $e');
        }
      });
    } catch (e) {
      return 'Failed to update shooter: $e';
    }
    return null;
  }

  /// Removes a shooter by name.
  Future<void> removeShooter(String name) async {
    await repository.removeShooter(name);
  }
}
