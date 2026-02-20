import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/match_stage.dart';

void main() {
  test('MatchStage toJson/fromJson and legacy keys', () {
    final m = MatchStage(stage: 5, scoringShoots: 10);
    final json = m.toJson();
    expect(json['stage'], 5);
    expect(json['scoringShoots'], 10);
    expect(json.containsKey('createdAtUtc'), isTrue);
    expect(json.containsKey('updatedAtUtc'), isTrue);

    // Simulate legacy map with old keys
    final legacy = {
      'stage': 7,
      'scoringShoots': 12,
      'createdAt': '2020-01-01T00:00:00',
      'updatedAt': '2020-01-02T00:00:00'
    };
    final fromLegacy = MatchStage.fromJson(legacy);
    expect(fromLegacy.stage, 7);
    expect(fromLegacy.scoringShoots, 12);
    expect(fromLegacy.createdAtUtc, equals('2020-01-01T00:00:00'));
    expect(fromLegacy.updatedAtUtc, equals('2020-01-02T00:00:00'));
  });

  test('MatchStage updatedAtUtc can be changed and preserved', () {
    final m = MatchStage(stage: 1, scoringShoots: 5);
    final oldUpdated = m.updatedAtUtc;
    m.updatedAtUtc = '2030-01-01T00:00:00Z';
    expect(m.updatedAtUtc, equals('2030-01-01T00:00:00Z'));
    expect(m.updatedAtUtc == oldUpdated, isFalse);
  });
}
