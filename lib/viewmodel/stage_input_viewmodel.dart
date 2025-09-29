

import 'package:flutter/foundation.dart';
import '../repository/match_repository.dart';
import '../models/stage_result.dart';


/// ViewModel for stage input page.
class StageInputViewModel extends ChangeNotifier {
  /// Reloads the current result from the repository into the ViewModel fields.
  void reload() {
    _loadOrReset();
    notifyListeners();
  }
  final MatchRepository repository;
  late final VoidCallback _repoListener;
  int? _selectedStage;
  String? _selectedShooter;
  double time = 0.0;
  int a = 0, c = 0, d = 0, misses = 0, noShoots = 0, procErrors = 0;

  StageInputViewModel(this.repository) {
    _repoListener = () => notifyListeners();
    repository.addListener(_repoListener);
  }

  void dispose() {
    repository.removeListener(_repoListener);
    super.dispose();
  }

  // Use public fields instead of unnecessary getters/setters
  int? get selectedStage => _selectedStage;
  String? get selectedShooter => _selectedShooter;

  void selectStage(int stage) {
    _selectedStage = stage;
    _loadOrReset();
  }

  void selectShooter(String shooter) {
    _selectedShooter = shooter;
    _loadOrReset();
  }

  void _loadOrReset() {
    if (_selectedStage == null || _selectedShooter == null) {
      _reset();
      return;
    }
    final result = repository.getResult(_selectedStage!, _selectedShooter!);
    if (result != null) {
      time = result.time;
      a = result.a;
      c = result.c;
      d = result.d;
      misses = result.misses;
      noShoots = result.noShoots;
      procErrors = result.procedureErrors;
    } else {
      _reset();
    }
  }

  void _reset() {
  time = 0.0;
  a = 0;
  c = 0;
  d = 0;
  misses = 0;
  noShoots = 0;
  procErrors = 0;
  }

  int get totalScore =>
  5 * a + 3 * c + 1 * d - 10 * misses - 10 * noShoots - 10 * procErrors;

  // Removed duplicate hitFactor getter; see below for correct version using 'time'.
  double get hitFactor => time > 0 ? totalScore / time : 0.0;

  double get adjustedHitFactor {
    final shooter = repository.getShooter(_selectedShooter ?? '');
    return shooter != null ? hitFactor * shooter.scaleFactor : 0.0;
  }

  bool get isValid {
  if (_selectedStage == null) return false;
  final stage = repository.getStage(_selectedStage!);
  if (stage == null) return false;
  return (a + c + d + misses) == stage.scoringShoots;
  }

  String? get validationError {
    if (_selectedStage == null) return null;
    final stage = repository.getStage(_selectedStage!);
    if (stage == null) return null;
    // Negative value check
    if (a < 0 || c < 0 || d < 0 || misses < 0 || noShoots < 0 || procErrors < 0 || time < 0) {
      return 'Values cannot be negative';
    }
    if ((a + c + d + misses) != stage.scoringShoots) {
      return 'A + C + D + Misses must equal ${stage.scoringShoots}';
    }
    return null;
  }

  Future<void> submit() async {
    if (_selectedStage == null || _selectedShooter == null) return;
    final result = StageResult(
      stage: _selectedStage!,
      shooter: _selectedShooter!,
      time: time,
      a: a,
      c: c,
      d: d,
      misses: misses,
      noShoots: noShoots,
      procedureErrors: procErrors,
    );
    final existing = repository.getResult(_selectedStage!, _selectedShooter!);
    if (existing == null) {
      await repository.addResult(result);
    } else {
      await repository.updateResult(result);
    }
  // After submit, reload fields from repository to update UI in-place
  _loadOrReset();
  notifyListeners();
  }

  Future<void> remove() async {
    if (_selectedStage == null || _selectedShooter == null) return;
    await repository.removeResult(_selectedStage!, _selectedShooter!);
    _reset();
  }
}
