import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/repository/match_repository.dart';

void main() {
  group('MatchRepository', () {
    late MatchRepository repo;
    setUp(() => repo = MatchRepository());

    test('initial lists are empty', () {
      expect(repo.stages, isEmpty);
      expect(repo.shooters, isEmpty);
      expect(repo.results, isEmpty);
    });

    test('can add and retrieve stages', () {
      final stage = MatchStage(stage: 1, scoringShoots: 10);
      repo.stages.add(stage);
      expect(repo.stages, contains(stage));
    });

    test('can add and retrieve shooters', () {
      final shooter = Shooter(name: 'Alice');
      repo.shooters.add(shooter);
      expect(repo.shooters, contains(shooter));
    });

    test('can add and retrieve results', () {
      final result = StageResult(stage: 1, shooter: 'Alice');
      repo.results.add(result);
      expect(repo.results, contains(result));
    });
  });
}
