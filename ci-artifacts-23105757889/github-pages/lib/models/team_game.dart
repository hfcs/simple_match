class Team {
  final String id;
  String name;
  List<String> members;

  Team({required this.id, required this.name, List<String>? members}) : members = members ?? [];

  factory Team.fromJson(Map<String, dynamic> m) => Team(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        members: (m['members'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members,
      };
}

class TeamGame {
  /// mode: 'off' | 'average' | 'top'
  String mode;
  int topCount;
  List<Team> teams;
  String createdAtUtc;
  String updatedAtUtc;

  TeamGame({this.mode = 'off', this.topCount = 0, List<Team>? teams, String? createdAtUtc, String? updatedAtUtc})
      : teams = teams ?? [],
        createdAtUtc = createdAtUtc ?? DateTime.now().toUtc().toIso8601String(),
        updatedAtUtc = updatedAtUtc ?? DateTime.now().toUtc().toIso8601String();

  factory TeamGame.fromJson(Map<String, dynamic> m) => TeamGame(
        mode: (m['mode'] as String?) ?? 'off',
        topCount: (m['topCount'] as int?) ?? 0,
        teams: (m['teams'] as List?)
                ?.map((e) => Team.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        createdAtUtc: (m['createdAtUtc'] as String?) ?? (m['createdAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
        updatedAtUtc: (m['updatedAtUtc'] as String?) ?? (m['updatedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'topCount': topCount,
        'teams': teams.map((t) => t.toJson()).toList(),
        'createdAtUtc': createdAtUtc,
        'updatedAtUtc': updatedAtUtc,
      };

  /// Compute the team score for [team] using provided shooter totals map.
  /// For `average` mode returns average of member totals.
  /// For `top` mode returns sum of top N member totals (N == topCount).
  double computeTeamScore(Team team, Map<String, double> shooterTotals) {
    final members = team.members;
    final memberTotals = members.map((m) => shooterTotals[m] ?? 0.0).toList();
    if (mode == 'average') {
      return memberTotals.isNotEmpty ? memberTotals.reduce((a, b) => a + b) / memberTotals.length : 0.0;
    }
    // default to 'top' behavior: sum top N
    final n = topCount <= 0 ? memberTotals.length : topCount;
    memberTotals.sort((a, b) => b.compareTo(a));
    return memberTotals.take(n).fold<double>(0.0, (p, e) => p + e);
  }
}
