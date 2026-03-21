import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/stage_result.dart';

void main() {
  test('totalScore computes sum with penalties', () {
    final r = StageResult(
      stage: 1,
      shooter: 'Test',
      time: 10.0,
      a: 4,
      c: 2,
      d: 1,
      misses: 1,
      noShoots: 0,
      procedureErrors: 1,
    );

    // totalScore = a*5 + c*3 + d*1 - (misses + noShoots + procErr)*10
    // = 4*5 + 2*3 + 1*1 - (1 + 0 + 1)*10 = 20 + 6 + 1 - 20 = 7
    expect(r.totalScore, equals(7));
  });

  test('hitFactor returns 0.0 when time is zero or negative', () {
    final rZero = StageResult(stage: 1, shooter: 'A', time: 0.0);
    expect(rZero.hitFactor, equals(0.0));

    final rNeg = StageResult(stage: 1, shooter: 'B', time: -5.0);
    expect(rNeg.hitFactor, equals(0.0));
  });

  test('hitFactor and adjustedHitFactor compute correctly', () {
    final r = StageResult(stage: 2, shooter: 'C', time: 5.0, a: 3, c: 0, d: 0);
    // totalScore = 3*5 = 15
    expect(r.totalScore, equals(15));
    expect(r.hitFactor, closeTo(3.0, 1e-9));

    // adjusted with scale factor
    expect(r.adjustedHitFactor(0.5), closeTo(1.5, 1e-9));
    expect(r.adjustedHitFactor(2.0), closeTo(6.0, 1e-9));
  });

  test('copyWith preserves unspecified fields and updates specified ones', () {
    final orig = StageResult(stage: 3, shooter: 'D', time: 8.0, a: 2, status: 'Completed');
    final copy = orig.copyWith(time: 10.0, a: 5, status: 'DNF');

    expect(copy.stage, equals(orig.stage));
    expect(copy.shooter, equals(orig.shooter));
    expect(copy.time, equals(10.0));
    expect(copy.a, equals(5));
    expect(copy.status, equals('DNF'));
  });

  test('toJson contains all expected keys and values', () {
    final r = StageResult(
      stage: 4,
      shooter: 'E',
      time: 3.5,
      a: 1,
      c: 1,
      d: 1,
      misses: 0,
      noShoots: 0,
      procedureErrors: 0,
      status: 'Custom',
    );

    final json = r.toJson();
    expect(json['stage'], equals(4));
    expect(json['shooter'], equals('E'));
    expect(json['time'], equals(3.5));
    expect(json['a'], equals(1));
    expect(json['c'], equals(1));
    expect(json['d'], equals(1));
    expect(json['status'], equals('Custom'));
  expect(json['roRemark'], equals(''));

    // Also verify round-trip via encode/decode
    final encoded = jsonEncode(json);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded['status'], equals('Custom'));
    expect(decoded['time'], equals(3.5));
  });

  test('default status is Completed and custom statuses are preserved', () {
    final def = StageResult(stage: 5, shooter: 'F');
    expect(def.status, equals('Completed'));
  expect(def.roRemark, equals(''));

    final dnf = StageResult(stage: 5, shooter: 'G', status: 'DNF');
    final dq = StageResult(stage: 5, shooter: 'H', status: 'DQ');
    expect(dnf.status, equals('DNF'));
    expect(dq.status, equals('DQ'));

    // Ensure toJson preserves the custom status
    expect(dnf.toJson()['status'], equals('DNF'));
    expect(dq.toJson()['status'], equals('DQ'));
  });

  test('copyWith without arguments returns equivalent values', () {
    final orig = StageResult(stage: 6, shooter: 'I', time: 2.5, a: 2, status: 'Custom');
    final copy = orig.copyWith();
    expect(copy.stage, equals(orig.stage));
    expect(copy.shooter, equals(orig.shooter));
    expect(copy.time, equals(orig.time));
    expect(copy.a, equals(orig.a));
    expect(copy.status, equals(orig.status));
  });

  test('adjustedHitFactor with zero scale returns zero', () {
    final r = StageResult(stage: 7, shooter: 'J', time: 4.0, a: 2);
    expect(r.hitFactor, greaterThan(0.0));
    expect(r.adjustedHitFactor(0.0), equals(0.0));
  });
}
