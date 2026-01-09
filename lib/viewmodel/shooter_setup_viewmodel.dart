import '../repository/match_repository.dart';
import '../models/shooter.dart';

/// ViewModel for shooter setup page.
class ShooterSetupViewModel {
  final MatchRepository repository;
  ShooterSetupViewModel(this.repository);

  /// Adds a shooter. Returns null on success, or error string on failure.
  String? addShooter(String name, double scaleFactor) {
    if (name.trim().isEmpty) return 'Name required.';
    if (scaleFactor < 0.1 || scaleFactor > 2.0) {
      return 'Invalid scale: must be between 0.100 and 2.000.';
    }
    if (repository.shooters.any((s) => s.name == name)) {
      return 'Shooter already exists.';
    }
    repository.addShooter(Shooter(name: name, scaleFactor: scaleFactor));
    return null;
  }

  /// Edits a shooter's scale. Returns null on success, or error string on failure.
  String? editShooter(String name, double scaleFactor) {
    if (scaleFactor < 0.1 || scaleFactor > 2.0) {
      return 'Invalid scale: must be between 0.100 and 2.000.';
    }
    final orig = repository.getShooter(name);
    if (orig == null) return 'Shooter not found.';
    // Preserve classificationScore when editing scale
    repository.updateShooter(Shooter(
      name: name,
      scaleFactor: scaleFactor,
      classificationScore: orig.classificationScore,
    ));
    return null;
  }

  /// Removes a shooter by name.
  void removeShooter(String name) {
    repository.removeShooter(name);
  }
}
