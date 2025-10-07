import 'package:flutter/foundation.dart';
import '../models/match_stage.dart';
import '../models/shooter.dart';
import '../models/stage_result.dart';
import '../services/persistence_service.dart';

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
  final PersistenceService? persistence;

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
          .map((e) => {'name': e.name, 'scaleFactor': e.scaleFactor})
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
            },
          )
          .toList(),
    );
  }

  Future<void> loadAll() async {
    if (persistence == null) return;
    await persistence!.ensureSchemaUpToDate();
    final stageList = await persistence!.loadList('stages');
    _stages
      ..clear()
      ..addAll(
        stageList.map(
          (e) =>
              MatchStage(stage: e['stage'], scoringShoots: e['scoringShoots']),
        ),
      );

    final shooterList = await persistence!.loadList('shooters');
    _shooters
      ..clear()
      ..addAll(
        shooterList.map(
          (e) => Shooter(
            name: e['name'],
            scaleFactor: (e['scaleFactor'] as num).toDouble(),
          ),
        ),
      );

    final resultList = await persistence!.loadList('stageResults');
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
          ),
        ),
      );
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
