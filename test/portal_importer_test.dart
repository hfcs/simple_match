import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/models/match_stage.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/services/portal_importer.dart';

void main() {
  const sampleHtml = '''
<!DOCTYPE html>
<html>
  <body>
    <div class="row mt-6 p-2" style="font-weight: bold;">
      <div class="col-4">
        181 Law, Tze Yeung            </div>
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
    expect(detail.name, 'Law, Tze Yeung');
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

  test('PortalImporter imports shooter detail into repository', () async {
    final importer = PortalImporter();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 24),
      MatchStage(stage: 2, scoringShoots: 12),
    ]);
    final detail = importer.parseShooterVerifyHtml(sampleHtml, 35, 181);

    final report = await importer.importShooterDetail(detail, repo, shooterName: 'Law, Tze Yeung', scaleFactor: 1.0);

    expect(report.success, isTrue);
    expect(report.shootersAdded, 1);
    expect(report.stagesAdded, 0);
    expect(report.resultsAdded, 2);
    expect(report.resultsUpdated, 0);
    expect(repo.shooters.length, 1);
    expect(repo.stages.length, 2);
    expect(repo.results.length, 2);
    expect(repo.getShooter('Law, Tze Yeung'), isNotNull);
  });

  test('PortalImporter rejects when shooter name already exists', () async {
    final importer = PortalImporter();
    final repo = MatchRepository(
      initialStages: [
        MatchStage(stage: 1, scoringShoots: 24),
        MatchStage(stage: 2, scoringShoots: 12),
      ],
      initialShooters: [Shooter(name: 'Law, Tze Yeung')],
    );
    final detail = importer.parseShooterVerifyHtml(sampleHtml, 35, 181);

    final report = await importer.importShooterDetail(detail, repo, shooterName: 'Law, Tze Yeung', scaleFactor: 1.0);

    expect(report.success, isFalse);
    expect(report.message, contains('already exists'));
  });

  test('PortalImporter rejects when imported stages do not match current setup', () async {
    final importer = PortalImporter();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 24),
      MatchStage(stage: 2, scoringShoots: 12),
      MatchStage(stage: 3, scoringShoots: 10),
    ]);
    final detail = importer.parseShooterVerifyHtml(sampleHtml, 35, 181);

    final report = await importer.importShooterDetail(detail, repo, shooterName: 'Law, Tze Yeung', scaleFactor: 1.0);

    expect(report.success, isFalse);
    expect(report.message, contains('does not match current match setup'));
  });

  test('PortalImporter rejects when scoring shoots do not agree with stage setup', () async {
    final importer = PortalImporter();
    final repo = MatchRepository(initialStages: [
      MatchStage(stage: 1, scoringShoots: 23),
      MatchStage(stage: 2, scoringShoots: 12),
    ]);
    final detail = importer.parseShooterVerifyHtml(sampleHtml, 35, 181);

    final report = await importer.importShooterDetail(detail, repo, shooterName: 'Law, Tze Yeung', scaleFactor: 1.0);

    expect(report.success, isFalse);
    expect(report.message, contains('Stage 1 is invalid'));
  });
}
