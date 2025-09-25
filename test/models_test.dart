import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  group('MatchStage', () {
    test('constructor assigns values', () {
      final stage = MatchStage(stage: 1, scoringShoots: 10);
      expect(stage.stage, 1);
      expect(stage.scoringShoots, 10);
    });
  });

  group('Shooter', () {
  test('constructor assigns name and default scale', () {
      final shooter = Shooter(name: 'Alice');
      expect(shooter.name, 'Alice');
  expect(shooter.scaleFactor, 1.0);
    });
  test('constructor assigns custom scale', () {
  final shooter = Shooter(name: 'Bob', scaleFactor: 0.85);
  expect(shooter.scaleFactor, 0.85);
    });
  });

  group('StageResult', () {
    test('constructor assigns all values', () {
      final result = StageResult(
        stage: 1,
        shooter: 'Alice',
        time: 12.34,
        a: 5,
        c: 3,
        d: 2,
        misses: 1,
        noShoots: 0,
        procedureErrors: 0,
      );
      expect(result.stage, 1);
      expect(result.shooter, 'Alice');
      expect(result.time, 12.34);
      expect(result.a, 5);
      expect(result.c, 3);
      expect(result.d, 2);
      expect(result.misses, 1);
      expect(result.noShoots, 0);
      expect(result.procedureErrors, 0);
    });
    test('constructor uses defaults', () {
      final result = StageResult(stage: 2, shooter: 'Bob');
      expect(result.time, 0.0);
      expect(result.a, 0);
      expect(result.c, 0);
      expect(result.d, 0);
      expect(result.misses, 0);
      expect(result.noShoots, 0);
      expect(result.procedureErrors, 0);
    });
  });
}
