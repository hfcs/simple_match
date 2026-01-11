import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/match_stage.dart';
import '../models/shooter.dart';
import '../models/stage_result.dart';
import '../services/persistence_service.dart';
import '../models/team_game.dart';

/// Repository for managing match data (stages, shooters, results).
class MatchRepository extends ChangeNotifier {
  /// Clears all match, shooter, and result data and persists the change.
  Future<void> clearAllData() async {
    _stages.clear();
    _shooters.clear();
    _results.clear();
    await saveAll();
    notifyListeners();
  }

  final List<MatchStage> _stages;
  final List<Shooter> _shooters;
  final List<StageResult> _results;
  TeamGame? _teamGame;
  final PersistenceService? persistence;
  /// When true, `loadAll` will use short timeouts around persistence calls
  /// to avoid blocking callers (used by import flows/tests).
  bool importMode = false;

  MatchRepository({
    this.persistence,
    List<MatchStage>? initialStages,
    List<Shooter>? initialShooters,
    List<StageResult>? initialResults,
  }) : _stages = initialStages ?? [],
       _shooters = initialShooters ?? [],
       _results = initialResults ?? [];
  // Persistence integration (stub)
  Future<void> saveAll() async {
    if (persistence == null) return;
    await persistence!.saveList(
      'stages',
      _stages
          .map((e) => {'stage': e.stage, 'scoringShoots': e.scoringShoots})
          .toList(),
    );
    await persistence!.saveList(
      'shooters',
      _shooters
          .map((e) => {
            'name': e.name,
            'scaleFactor': e.scaleFactor,
            'classificationScore': e.classificationScore,
          })
          .toList(),
    );
    await persistence!.saveList(
      'stageResults',
      _results
          .map(
            (e) => {
              'stage': e.stage,
              'shooter': e.shooter,
              'time': e.time,
              'a': e.a,
              'c': e.c,
              'd': e.d,
              'misses': e.misses,
              'noShoots': e.noShoots,
              'procedureErrors': e.procedureErrors,
              'status': e.status,
              'roRemark': e.roRemark,
            },
          )
          .toList(),
    );
    // Save team game configuration if present
    try {
      if (_teamGame != null) {
        await persistence!.saveTeamGame(_teamGame!.toJson());
      }
    } catch (_) {}
  }

  Future<void> loadAll() async {
    if (persistence == null) {
      if (kDebugMode) print('TESTDBG: repo.loadAll - persistence is null, returning');
      return;
    }
    if (kDebugMode) print('TESTDBG: repo.loadAll - start ${DateTime.now().toIso8601String()} importMode=$importMode');
    try {
      if (kDebugMode) print('TESTDBG: repo.loadAll - ensureSchemaUpToDate start');
      try {
        if (importMode) {
          await persistence!.ensureSchemaUpToDate().timeout(const Duration(seconds: 1));
        } else {
          await persistence!.ensureSchemaUpToDate();
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - ensureSchemaUpToDate timed out: $te');
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - ensureSchemaUpToDate done');

      if (kDebugMode) print('TESTDBG: repo.loadAll - loading stages');
      List<Map<String, dynamic>> stageList = <Map<String, dynamic>>[];
      try {
        if (importMode) {
          stageList = await persistence!.loadList('stages').timeout(const Duration(seconds: 1));
        } else {
          stageList = await persistence!.loadList('stages');
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadList(stages) timed out: $te');
        stageList = [];
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - stages loaded len=${stageList.length}');
      _stages
        ..clear()
        ..addAll(
          stageList.map(
            (e) => MatchStage(stage: e['stage'], scoringShoots: e['scoringShoots']),
          ),
        );

      if (kDebugMode) print('TESTDBG: repo.loadAll - loading shooters');
      List<Map<String, dynamic>> shooterList = <Map<String, dynamic>>[];
      try {
        if (importMode) {
          shooterList = await persistence!.loadList('shooters').timeout(const Duration(seconds: 1));
        } else {
          shooterList = await persistence!.loadList('shooters');
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadList(shooters) timed out: $te');
        shooterList = [];
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - shooters loaded len=${shooterList.length}');
      _shooters
        ..clear()
        ..addAll(
          shooterList.map(
            (e) => Shooter.fromJson(Map<String, dynamic>.from(e)),
          ),
        );

      if (kDebugMode) print('TESTDBG: repo.loadAll - loading results');
      List<Map<String, dynamic>> resultList = <Map<String, dynamic>>[];
      try {
        if (importMode) {
          resultList = await persistence!.loadList('stageResults').timeout(const Duration(seconds: 1));
        } else {
          resultList = await persistence!.loadList('stageResults');
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadList(stageResults) timed out: $te');
        resultList = [];
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - results loaded len=${resultList.length}');
      _results
        ..clear()
        ..addAll(
          resultList.map(
            (e) => StageResult(
              stage: e['stage'],
              shooter: e['shooter'],
              time: (e['time'] as num).toDouble(),
              a: e['a'],
              c: e['c'],
              d: e['d'],
              misses: e['misses'],
              noShoots: e['noShoots'],
              procedureErrors: e['procedureErrors'],
              status: (e['status'] as String?) ?? 'Completed',
              roRemark: (e['roRemark'] as String?) ?? '',
            ),
          ),
        );
      // Load team game config if present
      try {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loading team game');
        Map<String, dynamic>? tgRaw;
        try {
          if (importMode) {
            tgRaw = await persistence!.loadTeamGame().timeout(const Duration(seconds: 1));
          } else {
            tgRaw = await persistence!.loadTeamGame();
          }
        } on TimeoutException catch (te) {
          if (kDebugMode) print('TESTDBG: repo.loadAll - loadTeamGame timed out: $te');
          tgRaw = null;
        }
        if (tgRaw != null) {
          _teamGame = TeamGame.fromJson(tgRaw);
          if (kDebugMode) print('TESTDBG: repo.loadAll - team game loaded');
        } else {
          _teamGame = TeamGame();
          if (kDebugMode) print('TESTDBG: repo.loadAll - team game absent, created default');
        }
      } catch (e, st) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadTeamGame threw: $e\n$st');
        _teamGame = TeamGame();
      }
    } catch (e, st) {
      if (kDebugMode) print('TESTDBG: repo.loadAll - outer exception: $e\n$st');
    } finally {
      // Notify listeners so UI updates after a programmatic reload (e.g., after import)
      notifyListeners();
      if (kDebugMode) print('TESTDBG: repo.loadAll - completed ${DateTime.now().toIso8601String()}');
    }
  }

    TeamGame? get teamGame => _teamGame;

    Future<void> updateTeamGame(TeamGame tg) async {
      _teamGame = tg;
      if (persistence != null) {
        try {
          await persistence!.saveTeamGame(tg.toJson());
        } catch (_) {}
      }
      notifyListeners();
    }

  // Stages
  List<MatchStage> get stages => List.unmodifiable(_stages);
  Future<void> addStage(MatchStage stage) async {
    _stages.add(stage);
    await saveAll();
    notifyListeners();
  }

  Future<void> removeStage(int stageNumber) async {
    _stages.removeWhere((s) => s.stage == stageNumber);
    await saveAll();
    notifyListeners();
  }

  Future<void> updateStage(MatchStage updated) async {
    final idx = _stages.indexWhere((s) => s.stage == updated.stage);
    if (idx != -1) _stages[idx] = updated;
    await saveAll();
    notifyListeners();
  }

  // Shooters
  List<Shooter> get shooters => List.unmodifiable(_shooters);
  Future<void> addShooter(Shooter shooter) async {
    _shooters.add(shooter);
    await saveAll();
    notifyListeners();
  }

  Future<void> removeShooter(String name) async {
    _shooters.removeWhere((s) => s.name == name);
    await saveAll();
    notifyListeners();
  }

  Future<void> updateShooter(Shooter updated) async {
    final idx = _shooters.indexWhere((s) => s.name == updated.name);
    if (idx != -1) _shooters[idx] = updated;
    await saveAll();
    notifyListeners();
  }

  // Results
  List<StageResult> get results => List.unmodifiable(_results);
  Future<void> addResult(StageResult result) async {
    _results.add(result);
    await saveAll();
    notifyListeners();
  }

  Future<void> removeResult(int stage, String shooter) async {
    _results.removeWhere((r) => r.stage == stage && r.shooter == shooter);
    await saveAll();
    notifyListeners();
  }

  Future<void> updateResult(StageResult updated) async {
    final idx = _results.indexWhere(
      (r) => r.stage == updated.stage && r.shooter == updated.shooter,
    );
    if (idx != -1) _results[idx] = updated;
    await saveAll();
    notifyListeners();
  }

  // Getters for single items
  MatchStage? getStage(int stageNumber) {
    try {
      return _stages.firstWhere((s) => s.stage == stageNumber);
    } catch (_) {
      return null;
    }
  }

  Shooter? getShooter(String name) {
    try {
      return _shooters.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  StageResult? getResult(int stage, String shooter) {
    try {
      return _results.firstWhere(
        (r) => r.stage == stage && r.shooter == shooter,
      );
    } catch (_) {
      return null;
    }
  }
}
