/// Model for a match stage.
class MatchStage {
  final int stage;
  final int scoringShoots;
  // Audit timestamps (ISO8601 UTC)
  final String createdAtUtc;
  String updatedAtUtc;

  MatchStage({required this.stage, required this.scoringShoots, String? createdAtUtc, String? updatedAtUtc})
      : createdAtUtc = createdAtUtc ?? DateTime.now().toUtc().toIso8601String(),
        updatedAtUtc = updatedAtUtc ?? DateTime.now().toUtc().toIso8601String();

  factory MatchStage.fromJson(Map<String, dynamic> m) => MatchStage(
        stage: m['stage'] as int,
        scoringShoots: m['scoringShoots'] as int,
        createdAtUtc: (m['createdAtUtc'] as String?) ?? (m['createdAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
        updatedAtUtc: (m['updatedAtUtc'] as String?) ?? (m['updatedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'scoringShoots': scoringShoots,
        'createdAtUtc': createdAtUtc,
        'updatedAtUtc': updatedAtUtc,
      };
}
