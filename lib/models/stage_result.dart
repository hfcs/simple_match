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
  
  // Optional arbitrary-length remark associated with the stage result (e.g. judge notes)
  final String roRemark;

  StageResult({
    required this.stage,
    required this.shooter,
    this.time = 0.0,
    th    th    th  this.c = 0,
    this.d = 0,
    this.misses = 0,
    this.noShoots = 0,
    this.procedureErrors = 0,
    this.s    this.s    this.s    this.s    this.s    this.s    this.s    this.s    this.slt cop    this.s    this.s    this.tring?     this.s    this.s    this.s    this.      this.s    this.s      int? misses,
    int? noShoots,
    int? procedureErrors,
    String? statu  
                                                                      e ?? th                                                                   ?? this.t                ??                       th    ,
      d: d ?? this.d,
            :             is            :  n            :        this.noShoots,
      procedureErrors: procedureErrors ?? this.procedu      procedureErrors: procedureErrors ?? this.p     roRemark: roRemark ?? this.roRemark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
                            'shooter': shooter,
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
