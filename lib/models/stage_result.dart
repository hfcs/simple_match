/// Model for a stage result.
class StageResult {
  final int stage;
  final String shooter;
  double time;
  int a;
  int c;
  int d;
  int misses;
  int noShoots;
  int procedureErrors;

  StageResult({
    required this.stage,
    required this.shooter,
    this.time = 0.0,
    this.a = 0,
    this.c = 0,
    this.d = 0,
    this.misses = 0,
    this.noShoots = 0,
    this.procedureErrors = 0,
  });
}
