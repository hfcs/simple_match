/// Model for a shooter.
class Shooter {
  final String name;
  double scaleFactor;
  /// Classification score (percentage 0..100). Default 100.0 when unknown.
  double classificationScore;
  // Audit timestamps (ISO8601 UTC)
  final String createdAt;
  String updatedAt;

  Shooter({required this.name, this.scaleFactor = 1.0, this.classificationScore = 100.0, String? createdAt, String? updatedAt})
      : createdAt = createdAt ?? DateTime.now().toUtc().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toJson() => {
        'name': name,
        'scaleFactor': scaleFactor,
        'classificationScore': classificationScore,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Shooter.fromJson(Map<String, dynamic> m) => Shooter(
        name: m['name'] as String,
        scaleFactor: (m['scaleFactor'] as num?)?.toDouble() ?? 1.0,
        classificationScore: (m['classificationScore'] as num?)?.toDouble() ?? 100.0,
        createdAt: (m['createdAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
        updatedAt: (m['updatedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      );
}
