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
    // Use model `toJson()` so audit fields (`createdAtUtc`, `updatedAtUtc`) are persisted
    await persistence!.saveList('stages', _stages.map((e) => e.toJson()).toList());
    await persistence!.saveList('shooters', _shooters.map((e) => e.toJson()).toList());
    await persistence!.saveList('stageResults', _results.map((e) => e.toJson()).toList());
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
      List<MatchStage> loadedStages = [];
      try {
        if (importMode) {
          loadedStages = await persistence!.loadStages().timeout(const Duration(seconds: 1));
        } else {
          loadedStages = await persistence!.loadStages();
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadStages timed out: $te');
        loadedStages = [];
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - stages loaded len=${loadedStages.length}');
      _stages
        ..clear()
        ..addAll(loadedStages);

      if (kDebugMode) print('TESTDBG: repo.loadAll - loading shooters');
      List<Shooter> loadedShooters = [];
      try {
        if (importMode) {
          loadedShooters = await persistence!.loadShooters().timeout(const Duration(seconds: 1));
        } else {
          loadedShooters = await persistence!.loadShooters();
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadShooters timed out: $te');
        loadedShooters = [];
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - shooters loaded len=${loadedShooters.length}');
      _shooters
        ..clear()
        ..addAll(loadedShooters);

      if (kDebugMode) print('TESTDBG: repo.loadAll - loading results');
      List<StageResult> loadedResults = [];
      try {
        if (importMode) {
          loadedResults = await persistence!.loadStageResults().timeout(const Duration(seconds: 1));
        } else {
          loadedResults = await persistence!.loadStageResults();
        }
      } on TimeoutException catch (te) {
        if (kDebugMode) print('TESTDBG: repo.loadAll - loadStageResults timed out: $te');
        loadedResults = [];
      }
      if (kDebugMode) print('TESTDBG: repo.loadAll - results loaded len=${loadedResults.length}');
      _results
        ..clear()
        ..addAll(loadedResults);
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

  /// Load lists directly from the injected PersistenceService without
  /// invoking schema migration. This is used by tests which provide a
  /// mock PersistenceService that overrides the direct loaders.
  Future<void> loadFromPersistenceNoMigrate() async {
    if (persistence == null) {
      if (kDebugMode) print('TESTDBG: loadFromPersistenceNoMigrate - no persistence');
      return;
    }
    try {
      final loadedStages = await persistence!.loadStages();
      _stages
        ..clear()
        ..addAll(loadedStages);

      final loadedShooters = await persistence!.loadShooters();
      _shooters
        ..clear()
        ..addAll(loadedShooters);

      final loadedResults = await persistence!.loadStageResults();
      _results
        ..clear()
        ..addAll(loadedResults);
    } catch (e, st) {
      if (kDebugMode) print('TESTDBG: loadFromPersistenceNoMigrate threw: $e\n$st');
    } finally {
      notifyListeners();
      if (kDebugMode) print('TESTDBG: loadFromPersistenceNoMigrate - completed');
    }
  }

    TeamGame? get teamGame => _teamGame;

    Future<void> updateTeamGame(TeamGame tg) async {
        // update `updatedAtUtc` before persisting
        tg.updatedAtUtc = DateTime.now().toUtc().toIso8601String();
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
    final now = DateTime.now().toUtc().toIso8601String();
    stage.updatedAtUtc = now;
    _stages.add(stage);
    if (kDebugMode) {
      // quick debug trace for widget tests
      // ignore: avoid_print
      print('DBG: repo.addStage called, _stages.len=${_stages.length}');
    }
    // record audit log for create
    try {
      if (persistence != null) {
        await persistence!.appendLog('stagesLog', {
          'timestampUtc': DateTime.now().toUtc().toIso8601String(),
          'type': 'create',
          'channel': 'UI',
          'data': stage.toJson(),
        });
      }
    } catch (_) {}
    await saveAll();
    notifyListeners();
    if (kDebugMode) {
      // ignore: avoid_print
      print('DBG: repo.addStage completed notifyListeners');
    }
  }

  Future<void> removeStage(int stageNumber) async {
    final removed = _stages.where((s) => s.stage == stageNumber).toList();
    _stages.removeWhere((s) => s.stage == stageNumber);
    try {
      if (persistence != null) {
        for (final s in removed) {
          await persistence!.appendLog('stagesLog', {
            'timestampUtc': DateTime.now().toUtc().toIso8601String(),
            'type': 'delete',
            'channel': 'UI',
            'data': s.toJson(),
          });
        }
      }
    } catch (_) {}
    await saveAll();
    notifyListeners();
  }

  Future<void> updateStage(MatchStage updated) async {
    final idx = _stages.indexWhere((s) => s.stage == updated.stage);
    if (idx != -1) {
      final orig = _stages[idx];
      updated.updatedAtUtc = DateTime.now().toUtc().toIso8601String();
      _stages[idx] = updated;
      try {
        if (persistence != null) {
          await persistence!.appendLog('stagesLog', {
            'timestampUtc': DateTime.now().toUtc().toIso8601String(),
            'type': 'update',
            'channel': 'UI',
            'original': orig.toJson(),
            'updated': updated.toJson(),
          });
        }
      } catch (_) {}
    }
    await saveAll();
    notifyListeners();
  }

  // Shooters
  List<Shooter> get shooters => List.unmodifiable(_shooters);
  Future<void> addShooter(Shooter shooter) async {
    final now = DateTime.now().toUtc().toIso8601String();
    shooter.updatedAtUtc = now;
    _shooters.add(shooter);
    try {
      if (persistence != null) {
        await persistence!.appendLog('shootersLog', {
          'timestampUtc': DateTime.now().toUtc().toIso8601String(),
          'type': 'create',
          'channel': 'UI',
          'data': shooter.toJson(),
        });
      }
    } catch (_) {}
    await saveAll();
    notifyListeners();
  }

  Future<void> removeShooter(String name) async {
    final removed = _shooters.where((s) => s.name == name).toList();
    _shooters.removeWhere((s) => s.name == name);
    try {
      if (persistence != null) {
        for (final s in removed) {
          await persistence!.appendLog('shootersLog', {
            'timestampUtc': DateTime.now().toUtc().toIso8601String(),
            'type': 'delete',
            'channel': 'UI',
            'data': s.toJson(),
          });
        }
      }
    } catch (_) {}
    await saveAll();
    notifyListeners();
  }

  Future<void> updateShooter(Shooter updated) async {
    final idx = _shooters.indexWhere((s) => s.name == updated.name);
    if (idx != -1) {
      final orig = _shooters[idx];
      updated.updatedAtUtc = DateTime.now().toUtc().toIso8601String();
      _shooters[idx] = updated;
      try {
        if (persistence != null) {
          await persistence!.appendLog('shootersLog', {
            'timestampUtc': DateTime.now().toUtc().toIso8601String(),
            'type': 'update',
            'channel': 'UI',
            'original': orig.toJson(),
            'updated': updated.toJson(),
          });
        }
      } catch (_) {}
    }
    await saveAll();
    notifyListeners();
  }

  // Results
  List<StageResult> get results => List.unmodifiable(_results);
  Future<void> addResult(StageResult result) async {
    final now = DateTime.now().toUtc().toIso8601String();
    result.updatedAtUtc = now;
    _results.add(result);
    try {
      if (persistence != null) {
        await persistence!.appendLog('stageResultsLog', {
          'timestampUtc': DateTime.now().toUtc().toIso8601String(),
          'type': 'create',
          'channel': 'UI',
          'data': result.toJson(),
        });
      }
    } catch (_) {}
    await saveAll();
    notifyListeners();
  }

  Future<void> removeResult(int stage, String shooter) async {
    final removed = _results.where((r) => r.stage == stage && r.shooter == shooter).toList();
    _results.removeWhere((r) => r.stage == stage && r.shooter == shooter);
    try {
      if (persistence != null) {
        for (final r in removed) {
          await persistence!.appendLog('stageResultsLog', {
            'timestampUtc': DateTime.now().toUtc().toIso8601String(),
            'type': 'delete',
            'channel': 'UI',
            'data': r.toJson(),
          });
        }
      }
    } catch (_) {}
    await saveAll();
    notifyListeners();
  }

  Future<void> updateResult(StageResult updated) async {
    final idx = _results.indexWhere(
      (r) => r.stage == updated.stage && r.shooter == updated.shooter,
    );
    if (idx != -1) {
      final orig = _results[idx];
      updated.updatedAtUtc = DateTime.now().toUtc().toIso8601String();
      _results[idx] = updated;
      try {
        if (persistence != null) {
          await persistence!.appendLog('stageResultsLog', {
            'timestampUtc': DateTime.now().toUtc().toIso8601String(),
            'type': 'update',
            'channel': 'UI',
            'original': orig.toJson(),
            'updated': updated.toJson(),
          });
        }
      } catch (_) {}
    }
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
