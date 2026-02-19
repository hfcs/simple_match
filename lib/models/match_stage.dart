/// Model for a match stage.
class MatchStage {
  final int stage;
  final int scoringShoots;
  // Audit timestamps (ISO8601 UTC)
  final String createdAt;
  String updatedAt;

  MatchStage({required this.stage, required this.scoringShoots, String? createdAt, String? updatedAt})
      : createdAt = createdAt ?? DateTime.now().toUtc().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  factory MatchStage.fromJson(Map<String, dynamic> m) => MatchStage(
        stage: m['stage'] as int,
        scoringShoots: m['scoringShoots'] as int,
        createdAt: (m['createdAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
        updatedAt: (m['updatedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'scoringShoots': scoringShoots,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
