/// Model for a stage result.
class StageResult {
  // Returns the total score for this result (A=5, C=3, D=1, Miss=-10, NoShoots=-10, ProcErr=-10 each)
  int get totalScore => a * 5 + c * 3 + d * 1 - (misses + noShoots + procedureErrors) * 10;

  // Returns the hit factor (score/time)
  double get hitFactor => time > 0 ? totalScore / time : 0.0;

  // Returns the adjusted hit factor (hit factor * shooter's scale factor)
  double adjustedHitFactor(double scaleFactor) => hitFactor * scaleFactor;
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
