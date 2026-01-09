/// Model for a shooter.
class Shooter {
  final String name;
  double scaleFactor;
  /// Classification score (percentage 0..100). Default 100.0 when unknown.
  double classificationScore;

  Shooter({required this.name, this.scaleFactor = 1.0, this.classificationScore = 100.0});

  Map<String, dynamic> toJson() => {
        'name': name,
        'scaleFactor': scaleFactor,
        'classificationScore': classificationScore,
      };

  factory Shooter.fromJson(Map<String, dynamic> m) => Shooter(
        name: m['name'] as String,
        scaleFactor: (m['scaleFactor'] as num?)?.toDouble() ?? 1.0,
        classificationScore: (m['classificationScore'] as num?)?.toDouble() ?? 100.0,
      );
}
