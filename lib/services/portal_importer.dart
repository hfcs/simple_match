import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/match_stage.dart';
import '../models/shooter.dart';
import '../models/stage_result.dart';
import '../repository/match_repository.dart';

/// A detail row extracted from a portal verify page.
class PortalStageRow {
  final int stage;
  final double factor;
  final int points;
  final int a;
  final int c;
  final int d;
  final int misses;
  final int noShoots;
  final int procedureErrors;
  final double time;

  PortalStageRow({
    required this.stage,
    required this.factor,
    required this.points,
    required this.a,
    required this.c,
    required this.d,
    required this.misses,
    required this.noShoots,
    required this.procedureErrors,
    required this.time,
  });

  int get scoringShoots => a + c + d + misses;
}

/// A shooter detail page parsed from the IPSC portal.
class PortalShooterDetail {
  final int matchId;
  final int shooterNumber;
  final String name;
  final String division;
  final String shooterClass;
  final String powerFactor;
  final String category;
  final List<PortalStageRow> stageRows;

  PortalShooterDetail({
    required this.matchId,
    required this.shooterNumber,
    required this.name,
    this.division = '',
    this.shooterClass = '',
    this.powerFactor = '',
    this.category = '',
    required this.stageRows,
  });
}

/// Result returned by portal import operations.
class PortalImportReport {
  final bool success;
  final String message;
  final int stagesAdded;
  final int shootersAdded;
  final int resultsAdded;
  final int resultsUpdated;

  PortalImportReport({
    required this.success,
    required this.message,
    this.stagesAdded = 0,
    this.shootersAdded = 0,
    this.resultsAdded = 0,
    this.resultsUpdated = 0,
  });
}

/// Fetches shooter information from an IPSC portal verify page and converts
/// it into the app's model objects.
class PortalImporter {
  final http.Client _client;

  PortalImporter({
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  Uri _buildVerifyUriFromPortalUrl(String portalUrl, int shooterNumber) {
    final parsed = Uri.parse(portalUrl);
    if (parsed.queryParameters['match'] == null || parsed.queryParameters['match']!.isEmpty) {
      throw Exception('Portal URL must include a match query parameter, e.g. ?match=35');
    }
    final matchId = parsed.queryParameters['match']!;
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: '/portal/verify/$matchId',
      queryParameters: {'shooter': shooterNumber.toString()},
    );
  }

  Future<PortalShooterDetail> fetchShooterDetailFromUrl(String portalUrl, int shooterNumber) async {
    final uri = _buildVerifyUriFromPortalUrl(portalUrl, shooterNumber);
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch portal page: ${response.statusCode} ${response.reasonPhrase}');
    }
    final matchId = int.parse(Uri.parse(portalUrl).queryParameters['match']!);
    return parseShooterVerifyHtml(response.body, matchId, shooterNumber);
  }

  PortalShooterDetail parseShooterVerifyHtml(String html, int matchId, int shooterNumber) {
    final document = parse(html);
    final nameElement = document.querySelector('div.row.mt-6 .col-4');
    final headerElement = document.querySelector('div.row.mt-6 .col-8');
    final rawName = nameElement?.text.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    final name = rawName.replaceFirst(RegExp(r'^\s*\d+\s*'), '').trim();
    final headerText = headerElement?.text ?? '';

    final division = _extractField(headerText, 'DIV');
    final shooterClass = _extractField(headerText, 'CLASSE');
    final powerFactor = _extractField(headerText, 'FATOR');
    final category = _extractField(headerText, 'CAT');

    final rows = <PortalStageRow>[];
    final tableRows = document.querySelectorAll('table.table tbody tr');
    for (final row in tableRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 11) continue;
      final stageText = cells[0].text.trim();
      final stageNumber = _parseStageNumber(stageText);
      final factor = _parseDouble(cells[1].text);
      final points = _parseInt(cells[2].text);
      final a = _parseInt(cells[3].text);
      final c = _parseInt(cells[4].text);
      final d = _parseInt(cells[5].text);
      final misses = _parseInt(cells[6].text);
      final noShoots = _parseInt(cells[7].text);
      final procedureErrors = _parseInt(cells[8].text);
      final time = _parseDouble(cells[10].text);
      rows.add(PortalStageRow(
        stage: stageNumber,
        factor: factor,
        points: points,
        a: a,
        c: c,
        d: d,
        misses: misses,
        noShoots: noShoots,
        procedureErrors: procedureErrors,
        time: time,
      ));
    }

    if (rows.isEmpty) {
      throw Exception('Unable to parse any stage rows from verify page.');
    }

    return PortalShooterDetail(
      matchId: matchId,
      shooterNumber: shooterNumber,
      name: name,
      division: division,
      shooterClass: shooterClass,
      powerFactor: powerFactor,
      category: category,
      stageRows: rows,
    );
  }

  List<MatchStage> buildStagesFromShooter(PortalShooterDetail detail) {
    final stageMap = <int, int>{};
    for (final row in detail.stageRows) {
      stageMap.update(row.stage, (existing) => existing >= row.scoringShoots ? existing : row.scoringShoots,
          ifAbsent: () => row.scoringShoots);
    }
    final stages = stageMap.entries
        .map((entry) => MatchStage(stage: entry.key, scoringShoots: entry.value))
        .toList();
    stages.sort((a, b) => a.stage.compareTo(b.stage));
    return stages;
  }

  List<StageResult> buildStageResultsFromShooter(PortalShooterDetail detail) {
    return detail.stageRows.map((row) {
      return StageResult(
        stage: row.stage,
        shooter: detail.name,
        time: row.time,
        a: row.a,
        c: row.c,
        d: row.d,
        misses: row.misses,
        noShoots: row.noShoots,
        procedureErrors: row.procedureErrors,
        status: 'Completed',
        roRemark: 'Imported from portal verify page',
      );
    }).toList();
  }

  Future<PortalImportReport> importShooterToRepository(
    String portalUrl,
    int shooterNumber,
    MatchRepository repository,
    String shooterName,
    double scaleFactor, {
    bool overwriteExistingResults = false,
  }) async {
    final detail = await fetchShooterDetailFromUrl(portalUrl, shooterNumber);
    return importShooterDetail(
      detail,
      repository,
      shooterName: shooterName,
      scaleFactor: scaleFactor,
      overwriteExistingResults: overwriteExistingResults,
    );
  }

  Future<PortalImportReport> importShooterDetail(
    PortalShooterDetail detail,
    MatchRepository repository, {
    required String shooterName,
    required double scaleFactor,
    bool overwriteExistingResults = false,
  }) async {
    if (repository.getShooter(shooterName) != null) {
      return PortalImportReport(
        success: false,
        message: 'Shooter name "$shooterName" already exists in current match.',
      );
    }

    if (repository.stages.isEmpty) {
      return PortalImportReport(
        success: false,
        message: 'No stage setup exists in current match. Please configure stages before importing.',
      );
    }

    final expectedStages = repository.stages.map((s) => s.stage).toSet();
    final importedStages = detail.stageRows.map((r) => r.stage).toSet();
    if (expectedStages.length != importedStages.length || !expectedStages.containsAll(importedStages)) {
      return PortalImportReport(
        success: false,
        message:
            'Imported stage set does not match current match setup. Expected stages: ${expectedStages.toList()}. Imported stages: ${importedStages.toList()}.',
      );
    }

    var stagesAdded = 0;
    var shootersAdded = 0;
    var resultsAdded = 0;
    var resultsUpdated = 0;

    for (final row in detail.stageRows) {
      final existingStage = repository.getStage(row.stage);
      if (existingStage == null) {
        return PortalImportReport(
          success: false,
          message: 'Stage ${row.stage} is missing from current match setup.',
        );
      }

      final scoringShoots = existingStage.scoringShoots;
      final importedScoringShoots = row.a + row.c + row.d + row.misses;
      if (importedScoringShoots != scoringShoots) {
        return PortalImportReport(
          success: false,
          message:
              'Stage ${row.stage} is invalid: A+C+D+MI = $importedScoringShoots but expected $scoringShoots scoring shoots.',
        );
      }
    }

    for (final row in detail.stageRows) {
      final result = StageResult(
        stage: row.stage,
        shooter: shooterName,
        time: row.time,
        a: row.a,
        c: row.c,
        d: row.d,
        misses: row.misses,
        noShoots: row.noShoots,
        procedureErrors: row.procedureErrors,
        status: 'Completed',
        roRemark: 'Imported from portal verify page for ${detail.name}',
      );
      final existing = repository.getResult(result.stage, result.shooter);
      if (existing == null) {
        await repository.addResult(result);
        resultsAdded++;
      } else if (overwriteExistingResults) {
        await repository.updateResult(result);
        resultsUpdated++;
      }
    }

    await repository.addShooter(Shooter(name: shooterName, scaleFactor: scaleFactor));
    shootersAdded++;

    return PortalImportReport(
      success: true,
      message: 'Imported shooter $shooterName from match ${detail.matchId}.',
      stagesAdded: stagesAdded,
      shootersAdded: shootersAdded,
      resultsAdded: resultsAdded,
      resultsUpdated: resultsUpdated,
    );
  }

  int _parseStageNumber(String raw) {
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match == null) {
      throw FormatException('Invalid stage label: "$raw"');
    }
    return int.parse(match.group(0)!);
  }

  int _parseInt(String raw) {
    final sanitized = raw.trim().replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(sanitized) ?? 0;
  }

  double _parseDouble(String raw) {
    final sanitized = raw.trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  String _extractField(String text, String label) {
    final regex = RegExp('$label:\\s*(.*?)\\s*(?=[A-Z]+:|\\s*\$)');
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }
}
