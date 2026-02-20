/// Model for a shooter.
class Shooter {
  final String name;
  double scaleFactor;
  /// Classification score (percentage 0..100). Default 100.0 when unknown.
  double classificationScore;
  // Audit timestamps (ISO8601 UTC)
  final String createdAtUtc;
  String updatedAtUtc;

  Shooter({required this.name, this.scaleFactor = 1.0, this.classificationScore = 100.0, String? createdAtUtc, String? updatedAtUtc})
      : createdAtUtc = createdAtUtc ?? DateTime.now().toUtc().toIso8601String(),
        updatedAtUtc = updatedAtUtc ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toJson() => {
        'name': name,
        'scaleFactor': scaleFactor,
        'classificationScore': classificationScore,
      'createdAtUtc': createdAtUtc,
      'updatedAtUtc': updatedAtUtc,
      };

  factory Shooter.fromJson(Map<String, dynamic> m) => Shooter(
        name: m['name'] as String,
        scaleFactor: (m['scaleFactor'] as num?)?.toDouble() ?? 1.0,
        classificationScore: (m['classificationScore'] as num?)?.toDouble() ?? 100.0,
        createdAtUtc: (m['createdAtUtc'] as String?) ?? (m['createdAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
        updatedAtUtc: (m['updatedAtUtc'] as String?) ?? (m['updatedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      );
}
