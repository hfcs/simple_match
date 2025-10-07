import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/services/persistence_service.dart';

class TestPersistenceService extends PersistenceService {
  List<StageResult> stageResults = [];
  List<Shooter> shooters = [];
  List<MatchStage> stages = [];
  List<Map<String, dynamic>>? lastSaved;

  TestPersistenceService();

  @override
  Future<List<StageResult>> loadStageResults() async => stageResults;

  @override
  Future<List<Shooter>> loadShooters() async => shooters;

  @override
  Future<List<MatchStage>> loadStages() async => stages;

  @override
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    lastSaved = list;
  }
}

void main() {
  test('getStageRanks computes ordering and adjustedMatchPoint', () async {
    final svc = TestPersistenceService();

    // Two shooters with different scale factors
    svc.shooters = [
      Shooter(name: 'S1', scaleFactor: 1.0),
      Shooter(name: 'S2', scaleFactor: 2.0),
    ];

    // One stage with scoringShoots = 4
    svc.stages = [MatchStage(stage: 1, scoringShoots: 4)];

    // Create stage results such that S2 has higher adjusted hit factor
    // S1: totalScore=10, time=2 -> hitFactor=5, adjusted=5*1=5
    // S2: totalScore=8, time=2 -> hitFactor=4, adjusted=4*2=8
    final r1 = StageResult(stage: 1, shooter: 'S1', time: 2.0, a: 2, c: 0, d: 0);
    // Manually set fields to get desired totalScore
    // a=2 -> totalScore = 2*5 = 10

    final r2 = StageResult(stage: 1, shooter: 'S2', time: 2.0, a: 1, c: 1, d: 0);
    // a=1,c=1 -> totalScore = 1*5 + 1*3 = 8

    svc.stageResults = [r1, r2];

    final vm = StageResultViewModel(persistenceService: svc);
    // wait for initial load to complete
    await Future<void>.delayed(Duration.zero);

    final ranks = vm.getStageRanks();
    expect(ranks.containsKey(1), isTrue);
    final list = ranks[1]!;
    // S2 should be first because adjustedHitFactor 8 > 5
    expect(list.first.name, equals('S2'));
    expect(list.last.name, equals('S1'));

    // Check adjustedMatchPoint calculation for S1: (5/8)*scoringShoots*5
    final s1 = list.last;
    final expected = (s1.adjustedHitFactor / list.first.adjustedHitFactor) * 4 * 5;
    expect(s1.adjustedMatchPoint, closeTo(expected, 1e-9));
  });

  test('updateStatus updates result and saves via persistence', () async {
    final svc = TestPersistenceService();
    svc.shooters = [Shooter(name: 'T', scaleFactor: 1.0)];
    svc.stages = [MatchStage(stage: 10, scoringShoots: 3)];
    svc.stageResults = [
      StageResult(stage: 10, shooter: 'T', time: 1.0, a: 1, status: 'Completed')
    ];

    final vm = StageResultViewModel(persistenceService: svc);
    await Future<void>.delayed(Duration.zero);

    var notified = 0;
    vm.addListener(() {
      notified += 1;
    });

    await vm.updateStatus(10, 'T', 'DNF');

    // Verify model updated
    expect(vm.results.first.status, equals('DNF'));
    // Verify saveList was called and contains the updated status
    expect(svc.lastSaved, isNotNull);
    expect(svc.lastSaved!.first['status'], equals('DNF'));
    // Listener should have been notified once by updateStatus
    expect(notified, greaterThanOrEqualTo(1));
  });
}
