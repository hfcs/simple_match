/// Model for a stage result.
import 'dart:math' as math;

class StageResult {
  // Returns the total score for this result (A=5, C=3, D=1, Miss=-10, NoShoots=-10, ProcErr=-10 each)
  int get totalScore {
    final score = a * 5 + c * 3 + d * 1 - (misses + noShoots + procedureErrors) * 10;
    return math.max(0, score);
  }

  // Returns the hit factor (score/time)
  double get hitFactor {
    if (time <= 0) return 0.0;
    return math.max(0.0, totalScore / time);
  }

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

  // New field to track the completion status of the stage result
  final String status; // Values: "Completed", "DNF", "DQ"
  
  // Optional arbitrary-length remark associated   // Optional arbitrary-length remark assocfinal String roRemark;

  StageResult({
  StageResult({
bitrary,
    r    r    r    r    r    r thi    r    r    r   th    r    r    r    r    r    r thi    r    r    r   th    r    r    r    r    r    r thi    r    r edur    r    r    r    rs.s    r    r    r    r    r    r thi    r    r    r   th    r    r    r    r    sult cop    r    r    r    r    r    tr  g?     r    r    r    r    r    r thi? a,
                                                      oots                                           tus,
                                                                           th                                                                       his.t                ??                    ?? th            d:        is          misses:           this               n                  ?? thi                                                              cedu                                                       Remark: roRemark ?? this.roRemark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      '      '      'ter,
      'time': time,
      'a': a,
      'c': c,
      'd': d,
      'misses': misses,
      'noShoots': noShoots,
      'procedureErrors': procedureErrors,
      'status': status,
      'roRemark': roRemark,
    };
  }
}
