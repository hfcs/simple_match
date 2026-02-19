import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/persistence_service.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/team_game.dart';
import 'package:simple_match/models/match_stage.dart';

void main() {
  test('add then update operations modify updatedAt timestamps', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = PersistenceService(prefs: prefs);
    final repo = MatchRepository(persistence: svc);

    // ensure clean start
    await repo.loadAll();

    // Add shooter
    final shooter = Shooter(name: 'Bob', scaleFactor: 1.0);
    await repo.addShooter(shooter);

    // Read persisted shooter
    final shootersRaw = prefs.getString('shooters');
    expect(shootersRaw, isNotNull);
    final shooters = jsonDecode(shootersRaw!) as List;
    final sMap = Map<String, dynamic>.from(shooters.first as Map);
    final createdAt = sMap['createdAt'] as String;
    final updatedAt = sMap['updatedAt'] as String;
    expect(createdAt, isNotNull);
    expect(updatedAt, isNotNull);
    // createdAt should be <= updatedAt (constructors may call time twice)
    final createdDt = DateTime.parse(createdAt);
    final updatedDt = DateTime.parse(updatedAt);
    expect(createdDt.isBefore(updatedDt) || createdDt.isAtSameMomentAs(updatedDt), isTrue);

    // Wait and update shooter
    await Future.delayed(const Duration(milliseconds: 10));
    final updatedShooter = Shooter(name: 'Bob', scaleFactor: 2.0, createdAt: createdAt, updatedAt: updatedAt);
    await repo.updateShooter(updatedShooter);

    final shootersRaw2 = prefs.getString('shooters');
    final shooters2 = jsonDecode(shootersRaw2!) as List;
    final sMap2 = Map<String, dynamic>.from(shooters2.first as Map);
    final updatedAt2 = sMap2['updatedAt'] as String;
    expect(DateTime.parse(updatedAt2).isAfter(DateTime.parse(updatedAt)), isTrue);

    // Add stage and result then update result
    // Add a stage so scoringShoots validation isn't relied on here
    await repo.addStage(MatchStage(stage: 1, scoringShoots: 5));
    // Use raw StageResult to add
    final result = StageResult(stage: 1, shooter: 'Bob', time: 10.0, a: 5, c: 0, d: 0);
    await repo.addResult(result);
    final resultsRaw = prefs.getString('stageResults');
    expect(resultsRaw, isNotNull);
    final results = jsonDecode(resultsRaw!) as List;
    final rMap = Map<String, dynamic>.from(results.first as Map);
    final rCreated = rMap['createdAt'] as String;
    final rUpdated = rMap['updatedAt'] as String;
    await Future.delayed(const Duration(milliseconds: 10));
    final updatedResult = StageResult(stage: 1, shooter: 'Bob', time: 11.0, a: 5, c: 0, d: 0, createdAt: rCreated, updatedAt: rUpdated);
    await repo.updateResult(updatedResult);
    final resultsRaw2 = prefs.getString('stageResults');
    final results2 = jsonDecode(resultsRaw2!) as List;
    final rMap2 = Map<String, dynamic>.from(results2.first as Map);
    final rUpdated2 = rMap2['updatedAt'] as String;
    expect(DateTime.parse(rUpdated2).isAfter(DateTime.parse(rUpdated)), isTrue);

    // TeamGame update
    final tg = TeamGame();
    await repo.updateTeamGame(tg);
    final tgRaw = prefs.getString('teamGame');
    expect(tgRaw, isNotNull);
    final tgMap = jsonDecode(tgRaw!) as Map<String, dynamic>;
    final tgCreated = tgMap['createdAt'] as String;
    final tgUpdated = tgMap['updatedAt'] as String;
    expect(tgCreated, isNotNull);
    await Future.delayed(const Duration(milliseconds: 10));
    tg.mode = 'average';
    await repo.updateTeamGame(tg);
    final tgRaw2 = prefs.getString('teamGame');
    final tgMap2 = jsonDecode(tgRaw2!) as Map<String, dynamic>;
    final tgUpdated2 = tgMap2['updatedAt'] as String;
    expect(DateTime.parse(tgUpdated2).isAfter(DateTime.parse(tgUpdated)), isTrue);
  });
}

// no-op
