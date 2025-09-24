
import '../repository/match_repository.dart';
import '../models/stage_result.dart';


/// ViewModel for stage input page.
class StageInputViewModel {
  final MatchRepository repository;
  int? _selectedStage;
  String? _selectedShooter;
  double _time = 0.0;
  int _a = 0, _c = 0, _d = 0, _misses = 0, _noShoots = 0, _procErrors = 0;

  StageInputViewModel(this.repository);

  int? get selectedStage => _selectedStage;
  String? get selectedShooter => _selectedShooter;
  double get time => _time;
  int get a => _a;
  int get c => _c;
  int get d => _d;
  int get misses => _misses;
  int get noShoots => _noShoots;
  int get procErrors => _procErrors;

  set time(double v) => _time = v;
  set a(int v) => _a = v;
  set c(int v) => _c = v;
  set d(int v) => _d = v;
  set misses(int v) => _misses = v;
  set noShoots(int v) => _noShoots = v;
  set procErrors(int v) => _procErrors = v;

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
      _time = result.time;
      _a = result.a;
      _c = result.c;
      _d = result.d;
      _misses = result.misses;
      _noShoots = result.noShoots;
      _procErrors = result.procedureErrors;
    } else {
      _reset();
    }
  }

  void _reset() {
    _time = 0.0;
    _a = 0;
    _c = 0;
    _d = 0;
    _misses = 0;
    _noShoots = 0;
    _procErrors = 0;
  }

  int get totalScore =>
      5 * _a + 3 * _c + 1 * _d - 10 * _misses - 10 * _noShoots - 10 * _procErrors;

  double get hitFactor => _time > 0 ? totalScore / _time : 0.0;

  double get adjustedHitFactor {
    final shooter = repository.getShooter(_selectedShooter ?? '');
    return shooter != null ? hitFactor * shooter.handicapFactor : 0.0;
  }

  bool get isValid {
    if (_selectedStage == null) return false;
    final stage = repository.getStage(_selectedStage!);
    if (stage == null) return false;
    return (_a + _c + _d + _misses) == stage.scoringShoots;
  }

  String? get validationError {
    if (_selectedStage == null) return null;
    final stage = repository.getStage(_selectedStage!);
    if (stage == null) return null;
    if ((_a + _c + _d + _misses) != stage.scoringShoots) {
      return 'A + C + D + Misses must equal ${stage.scoringShoots}';
    }
    return null;
  }

  void submit() {
    if (_selectedStage == null || _selectedShooter == null) return;
    final result = StageResult(
      stage: _selectedStage!,
      shooter: _selectedShooter!,
      time: _time,
      a: _a,
      c: _c,
      d: _d,
      misses: _misses,
      noShoots: _noShoots,
      procedureErrors: _procErrors,
    );
    final existing = repository.getResult(_selectedStage!, _selectedShooter!);
    if (existing == null) {
      repository.addResult(result);
    } else {
      repository.updateResult(result);
    }
  }

  void remove() {
    if (_selectedStage == null || _selectedShooter == null) return;
  repository.removeResult(_selectedStage!, _selectedShooter!);
    _reset();
  }
}
