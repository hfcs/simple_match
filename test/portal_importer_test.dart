import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/portal_importer.dart';

void main() {
  const sampleHtml = '''
<!DOCTYPE html>
<html>
  <body>
    <div class="row mt-6 p-2" style="font-weight: bold;">
      <div class="col-4">
        Sample Shooter 181            </div>
      <div class="col-8 text-right">
        DIV: Open                CLASSE: B                FATOR: Minor  CAT:              </div>
    </div>
    <table class="table">
      <thead>
      <tr>
        <th>STG</th>
        <th>FACTOR</th>
        <th>PTS</th>
        <th>A</th>
        <th>C</th>
        <th>D</th>
        <th>MI</th>
        <th>NS</th>
        <th>PE</th>
        <th>&nbsp;</th>
        <th>TIME</th>
      </tr>
      </thead>
      <tbody>
        <tr>
          <td>Stage 1</td>
          <td>6.8069</td>
          <td>110</td>
          <td>20</td>
          <td>3</td>
          <td>1</td>
          <td>0</td>
          <td>0</td>
          <td>0</td>
          <td>&nbsp;</td>
          <td>16.16</td>
        </tr>
        <tr>
          <td>Stage 2</td>
          <td>5.7199</td>
          <td>58</td>
          <td>11</td>
          <td>1</td>
          <td>0</td>
          <td>0</td>
          <td>0</td>
          <td>0</td>
          <td>&nbsp;</td>
          <td>10.14</td>
        </tr>
      </tbody>
    </table>
  </body>
</html>
''';

  test('PortalImporter parses verify page HTML correctly', () {
    final importer = PortalImporter();
    final detail = importer.parseShooterVerifyHtml(sampleHtml, 35, 181);

    expect(detail.matchId, 35);
    expect(detail.shooterNumber, 181);
    expect(detail.name, 'Sample Shooter 181');
    expect(detail.division, 'Open');
    expect(detail.shooterClass, 'B');
    expect(detail.powerFactor, 'Minor');
    expect(detail.category, '');
    expect(detail.stageRows, hasLength(2));

    final firstStage = detail.stageRows.first;
    expect(firstStage.stage, 1);
    expect(firstStage.factor, closeTo(6.8069, 1e-6));
    expect(firstStage.points, 110);
    expect(firstStage.a, 20);
    expect(firstStage.c, 3);
    expect(firstStage.d, 1);
    expect(firstStage.misses, 0);
    expect(firstStage.noShoots, 0);
    expect(firstStage.procedureErrors, 0);
    expect(firstStage.time, closeTo(16.16, 1e-6));
  });

  test('PortalImporter accepts a valid shooter page with an empty score table', () {
    const emptyTableHtml = '''
<!DOCTYPE html>
<html>
  <body>
    <div class="row mt-6 p-2" style="font-weight: bold;">
      <div class="col-4">Sample Shooter 3</div>
      <div class="col-8 text-right">DIV: Classic CLASSE: U FATOR: Minor CAT: Senior</div>
    </div>
    <table class="table">
      <thead class="thead-dark">
        <tr><th>STG</th><th>FACTOR</th><th>PTS</th><th>A</th><th>C</th><th>D</th><th>MI</th><th>NS</th><th>PE</th><th>&nbsp;</th><th>TIME</th></tr>
      </thead>
      <tbody>
      </tbody>
    </table>
  </body>
</html>
''';

    final detail = PortalImporter().parseShooterVerifyHtml(emptyTableHtml, 35, 3);

    expect(detail.shooterNumber, 3);
    expect(detail.name, 'Sample Shooter 3');
    expect(detail.stageRows, isEmpty);
  });

  test('PortalImporter treats a not-found ESS page as a missing shooter, not a parse failure', () {
    const notFoundHtml = '''
<!DOCTYPE html>
<html>
  <body>
    <h2>Shooter not found.</h2>
  </body>
</html>
''';

    expect(
      () => PortalImporter().parseShooterVerifyHtml(notFoundHtml, 35, 206),
      throwsA(isA<Exception>()),
    );
  });

  test('PortalImporter imports shooter detail into repository', () async {
    final importer = PortalImporter();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 24),
      MatchStage(stage: 2, scoringShoots: 12),
    ]);
    final detail = importer.parseShooterVerifyHtml(sampleHtml, 35, 181);

    final report = await importer.importShooterDetail(detail, repo, shooterName: 'Sample Shooter 181', scaleFactor: 1.0);

    expect(report.success, isTrue);
    expect(report.shootersAdded, 1);
    expect(report.stagesAdded, 0);
    expect(report.resultsAdded, 2);
    expect(report.resultsUpdated, 0);
    expect(repo.shooters.length, 1);
    expect(repo.stages.length, 2);
    expect(repo.results.length, 2);
    expect(repo.getShooter('Sample Shooter 181'), isNotNull);
  });

  test('PortalImporter auto-creates match stages from ESS rows when none are configured', () async {
    final importer = _NoStagesHarness();
    final repo = MatchRepository();

    final report = await importer.importAllShootersFromPortal(
      portalUrl: 'https://ess.example/portal?match=35',
      startShooterNumber: 1,
      endShooterNumber: 2,
      repository: repo,
      scaleFactor: 1.0,
    );

    expect(report.success, isTrue);
    expect(report.totalProcessed, 2);
    expect(report.shootersAdded, 2);
    expect(report.resultsAdded, 2);
    expect(repo.stages.map((s) => s.stage), containsAll([1]));
    expect(repo.stages.first.scoringShoots, 24);
  });

  test('PortalImporter skips missing shooters in a manual range and continues', () async {
    final importer = _MissingShooterInRangeHarness();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 24),
    ]);

    final report = await importer.importAllShootersFromPortal(
      portalUrl: 'https://ess.example/portal?match=35',
      startShooterNumber: 1,
      endShooterNumber: 3,
      repository: repo,
      scaleFactor: 1.0,
    );

    expect(report.success, isTrue);
    expect(report.totalProcessed, 2);
    expect(report.shootersAdded, 2);
    expect(report.resultsAdded, 2);
    expect(report.message, contains('skipped 1 requests'));
    expect(repo.shooters.map((s) => s.name), containsAll(['Shooter 1', 'Shooter 3']));
  });

  test('PortalImporter can export a CSV directly from the repository', () {
    final importer = PortalImporter();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 24),
    ], initialShooters: [
      Shooter(name: 'Alpha', scaleFactor: 1.0),
      Shooter(name: 'Bravo', scaleFactor: 1.0),
    ], initialResults: [
      StageResult(stage: 1, shooter: 'Alpha', time: 10.0, a: 5, c: 3, d: 1, misses: 0, noShoots: 0, procedureErrors: 0, status: 'Completed'),
      StageResult(stage: 1, shooter: 'Bravo', time: 12.0, a: 4, c: 2, d: 1, misses: 1, noShoots: 0, procedureErrors: 0, status: 'Completed'),
    ]);

    final csv = importer.buildEssStageCsvFromRepository(repo);
    expect(csv, contains('shooterName,stageNumber,rawHitFactor,points,a,c,d,misses,noShoots,procedureErrors,time'));
    expect(csv, contains('Alpha'));
    expect(csv, contains('Bravo'));
    expect(csv, isNot(contains('shooterNumber,')));
    expect(csv, isNot(contains('status')));
  });

  test('PortalImporter builds raw ESS stage CSV without scaling', () {
    final importer = PortalImporter();
    final csv = importer.buildEssStageCsvFromDetails([
      PortalShooterDetail(
        matchId: 35,
        shooterNumber: 181,
        name: 'Sample Shooter 181',
        stageRows: [
          PortalStageRow(
            stage: 1,
            factor: 6.8069,
            points: 110,
            a: 20,
            c: 3,
            d: 1,
            misses: 0,
            noShoots: 0,
            procedureErrors: 0,
            statusText: 'Completed',
            time: 16.16,
          ),
        ],
      ),
    ]);

    expect(csv, contains('shooterNumber,shooterName,stageNumber,rawHitFactor,points,a,c,d,misses,noShoots,procedureErrors,time'));
    expect(csv, contains('181,Sample Shooter 181,1,6.8069,110,20,3,1,0,0,0,16.16'));
    expect(csv, isNot(contains('status')));
  });

  test('PortalImporter uses polite adaptive pauses for bulk match imports', () {
    final importer = PortalImporter();

    expect(
      importer.computeNextQueryDelay(responseTime: const Duration(milliseconds: 500), hadResponse: true),
      const Duration(seconds: 2),
    );
    expect(
      importer.computeNextQueryDelay(responseTime: const Duration(milliseconds: 4500), hadResponse: true),
      const Duration(seconds: 5),
    );
    expect(
      importer.computeNextQueryDelay(responseTime: const Duration(milliseconds: 0), hadResponse: false),
      const Duration(seconds: 5),
    );
  });

  test('PortalImporter discovers the last valid shooter number with a high-start binary search', () async {
    final importer = _DiscoveryHarness();

    final lastShooter = await importer.detectLastShooterNumber(
      'https://ess.example/portal?match=35',
      startShooterNumber: 1,
      maxAttempts: 300,
    );

    expect(lastShooter, 205);
    expect(importer.requestedNumbers.first, 250);
    expect(importer.requestedNumbers.any((n) => n > 205), isTrue);
  });

  test('PortalImporter reports elapsed duration for the bulk import', () async {
    final importer = _BulkImportHarness();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 24),
    ]);

    final report = await importer.importAllShootersFromPortal(
      portalUrl: 'https://ess.example/portal?match=35',
      startShooterNumber: 1,
      endShooterNumber: 2,
      repository: repo,
      scaleFactor: 1.0,
    );

    expect(report.elapsedDuration, isA<Duration>());
    expect(report.elapsedDuration.inMilliseconds, greaterThanOrEqualTo(0));
    expect(report.message, contains('took '));
  });
}

class _BulkImportHarness extends PortalImporter {
  final List<int> requestOrder = <int>[];
  final List<Duration> pauseDurations = <Duration>[];

  @override
  Future<PortalShooterDetail> fetchShooterDetailFromUrl(String portalUrl, int shooterNumber) async {
    requestOrder.add(shooterNumber);
    await Future.delayed(const Duration(milliseconds: 200));
    return PortalShooterDetail(
      matchId: 35,
      shooterNumber: shooterNumber,
      name: 'Shooter $shooterNumber',
      stageRows: [
        PortalStageRow(
          stage: 1,
          factor: 1.0,
          points: 100,
          a: 20,
          c: 3,
          d: 1,
          misses: 0,
          noShoots: 0,
          procedureErrors: 0,
          time: 10.0,
        ),
      ],
    );
  }

  @override
  Future<void> delayBeforeNextRequest(Duration delay) async {
    pauseDurations.add(delay);
    await Future<void>.delayed(delay);
  }
}

class _DiscoveryHarness extends PortalImporter {
  final List<int> requestedNumbers = <int>[];

  @override
  Future<PortalShooterDetail> fetchShooterDetailFromUrl(String portalUrl, int shooterNumber) async {
    requestedNumbers.add(shooterNumber);
    if (shooterNumber >= 206) {
      throw Exception('not found');
    }
    return PortalShooterDetail(
      matchId: 35,
      shooterNumber: shooterNumber,
      name: 'Shooter $shooterNumber',
      stageRows: [
        PortalStageRow(
          stage: 1,
          factor: 1.0,
          points: 100,
          a: 20,
          c: 3,
          d: 1,
          misses: 0,
          noShoots: 0,
          procedureErrors: 0,
          time: 10.0,
        ),
      ],
    );
  }
}

class _NoStagesHarness extends PortalImporter {
  @override
  Future<PortalShooterDetail> fetchShooterDetailFromUrl(String portalUrl, int shooterNumber) async {
    return PortalShooterDetail(
      matchId: 35,
      shooterNumber: shooterNumber,
      name: 'Shooter $shooterNumber',
      stageRows: [
        PortalStageRow(
          stage: 1,
          factor: 1.0,
          points: 100,
          a: 20,
          c: 3,
          d: 1,
          misses: 0,
          noShoots: 0,
          procedureErrors: 0,
          time: 10.0,
        ),
      ],
    );
  }
}

class _MissingShooterInRangeHarness extends PortalImporter {
  @override
  Future<PortalShooterDetail> fetchShooterDetailFromUrl(String portalUrl, int shooterNumber) async {
    if (shooterNumber == 2) {
      throw Exception('Shooter $shooterNumber not found on ESS portal.');
    }

    return PortalShooterDetail(
      matchId: 35,
      shooterNumber: shooterNumber,
      name: 'Shooter $shooterNumber',
      stageRows: [
        PortalStageRow(
          stage: 1,
          factor: 1.0,
          points: 100,
          a: 20,
          c: 3,
          d: 1,
          misses: 0,
          noShoots: 0,
          procedureErrors: 0,
          time: 10.0,
        ),
      ],
    );
  }
}
