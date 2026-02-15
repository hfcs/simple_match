// Model for a stage result.
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
    this.a = 0,
    this.c = 0,
    this.d = 0,
    this.misses = 0,
    this.noShoots = 0,
    this.procedureErrors = 0,
    this.status = "Completed", // Default value
  this.roRemark = '',
  });

  StageResult copyWith({
    int? stage,
    String? shooter,
    double? time,
    int? a,
    int? c,
    int? d,
    int? misses,
    int? noShoots,
    int? procedureErrors,
    String? status,
  String? roRemark,
  }) {
    return StageResult(
      stage: stage ?? this.stage,
      shooter: shooter ?? this.shooter,
      time: time ?? this.time,
      a: a ?? this.a,
      c: c ?? this.c,
      d: d ?? this.d,
      misses: misses ?? this.misses,
      noShoots: noShoots ?? this.noShoots,
      procedureErrors: procedureErrors ?? this.procedureErrors,
      status: status ?? this.status,
  roRemark: roRemark ?? this.roRemark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
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
