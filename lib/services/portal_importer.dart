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
  final String statusText;
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
    this.statusText = '',
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
  final int totalProcessed;
  final int? lastShooterNumber;
  final Duration elapsedDuration;

  PortalImportReport({
    required this.success,
    required this.message,
    this.stagesAdded = 0,
    this.shootersAdded = 0,
    this.resultsAdded = 0,
    this.resultsUpdated = 0,
    this.totalProcessed = 0,
    this.lastShooterNumber,
    this.elapsedDuration = Duration.zero,
  });
}

/// Fetches shooter information from an IPSC portal verify page and converts
/// it into the app's model objects.
class PortalImporter {
  final http.Client _client;
  final bool _debugEnabled;
  final void Function(String message)? _logger;

  PortalImporter({
    http.Client? httpClient,
    bool debugEnabled = false,
    void Function(String message)? logger,
  }) : _client = httpClient ?? http.Client(),
       _debugEnabled = debugEnabled,
       _logger = logger ?? (debugEnabled ? print : null);

  void _debugLog(String message) {
    if (_debugEnabled) {
      (_logger ?? print)(message);
    }
  }

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
    _debugLog('[ESS_DEBUG] fetching shooter $shooterNumber from $uri');
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    _debugLog('[ESS_DEBUG] shooter $shooterNumber response status=${response.statusCode} reason=${response.reasonPhrase} bytes=${response.body.length}');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch portal page: ${response.statusCode} ${response.reasonPhrase}');
    }
    final matchId = int.parse(Uri.parse(portalUrl).queryParameters['match']!);
    final detail = parseShooterVerifyHtml(response.body, matchId, shooterNumber);
    _debugLog('[ESS_DEBUG] parsed shooter $shooterNumber name=${detail.name} stages=${detail.stageRows.length}');
    return detail;
  }

  String buildEssStageCsvFromRepository(MatchRepository repository) {
    final lines = <String>[
      'shooterName,division,shooterClass,category,stageNumber,rawHitFactor,points,a,c,d,misses,noShoots,procedureErrors,time',
    ];

    final allResults = <StageResult>[];
    for (final shooter in repository.shooters) {
      final shooterResults = repository.results.where((result) => result.shooter == shooter.name).toList()
        ..sort((a, b) => a.stage.compareTo(b.stage));
      allResults.addAll(shooterResults);
    }

    allResults.sort((a, b) {
      final byShooter = a.shooter.compareTo(b.shooter);
      if (byShooter != 0) return byShooter;
      return a.stage.compareTo(b.stage);
    });

    for (final result in allResults) {
      final shooter = repository.shooters.firstWhere(
        (candidate) => candidate.name == result.shooter,
        orElse: () => Shooter(name: result.shooter),
      );
      final safeName = result.shooter.replaceAll('"', '""');
      final escapedName = safeName.contains(',') || safeName.contains('"') || safeName.contains('\n')
          ? '"$safeName"'
          : safeName;

      final hitFactor = result.time <= 0 ? 0.0 : result.totalScore / result.time;
      lines.add([
        escapedName,
        shooter.division,
        shooter.shooterClass,
        shooter.category,
        result.stage,
        hitFactor,
        result.totalScore,
        result.a,
        result.c,
        result.d,
        result.misses,
        result.noShoots,
        result.procedureErrors,
        result.time,
      ].map((value) => value.toString()).join(','));
    }

    return lines.join('\n');
  }

  String buildEssStageCsvFromDetails(List<PortalShooterDetail> details) {
    final lines = <String>[
      'shooterNumber,shooterName,division,shooterClass,category,stageNumber,rawHitFactor,points,a,c,d,misses,noShoots,procedureErrors,time',
    ];

    for (final detail in details) {
      for (final row in detail.stageRows) {
        final safeName = detail.name.replaceAll('"', '""');
        final escapedName = safeName.contains(',') || safeName.contains('"') || safeName.contains('\n')
            ? '"$safeName"'
            : safeName;
        lines.add([
          detail.shooterNumber,
          escapedName,
          detail.division,
          detail.shooterClass,
          detail.category,
          row.stage,
          row.factor,
          row.points,
          row.a,
          row.c,
          row.d,
          row.misses,
          row.noShoots,
          row.procedureErrors,
          row.time,
        ].map((value) => value.toString()).join(','));
      }
    }

    return lines.join('\n');
  }

  Future<List<PortalShooterDetail>> extractShooterDetailsFromPortal({
    required String portalUrl,
    required int startShooterNumber,
    int? endShooterNumber,
    void Function(int currentShooterNumber, int totalRange, String status)? onProgress,
  }) async {
    if (startShooterNumber < 1) {
      throw ArgumentError.value(startShooterNumber, 'startShooterNumber', 'must be positive');
    }

    final totalRange = endShooterNumber == null ? null : endShooterNumber - startShooterNumber + 1;
    final details = <PortalShooterDetail>[];
    var shooterNumber = startShooterNumber;

    while (endShooterNumber == null || shooterNumber <= endShooterNumber) {
      try {
        onProgress?.call(shooterNumber, totalRange ?? 0, 'Fetching shooter $shooterNumber');
        final detail = await fetchShooterDetailFromUrl(portalUrl, shooterNumber);
        details.add(detail);
        onProgress?.call(shooterNumber, totalRange ?? 0, detail.name);

        if (endShooterNumber != null && shooterNumber >= endShooterNumber) {
          break;
        }

        final delay = computeNextQueryDelay(
          responseTime: const Duration(milliseconds: 200),
          hadResponse: true,
        );
        await delayBeforeNextRequest(delay);
        shooterNumber++;
      } catch (_) {
        break;
      }
    }

    return details;
  }

  PortalShooterDetail parseShooterVerifyHtml(String html, int matchId, int shooterNumber) {
    final document = parse(html);
    final textContent = document.body?.text ?? html;
    final normalizedText = textContent.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalizedText.contains('Shooter not found') || normalizedText.contains('not found')) {
      throw Exception('Shooter $shooterNumber not found on ESS portal.');
    }

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
      final statusText = cells.length > 9 ? cells[9].text.trim() : '';
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
        statusText: statusText,
        time: time,
      ));
    }

    if (name.isEmpty && headerText.isEmpty && rows.isEmpty) {
      throw Exception('Unable to parse any shooter data from verify page.');
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
      final text = row.statusText.toUpperCase();
      final isDq = text.contains('DQ');
      final isDnf = isDq || text.contains('DNF') ||
          (row.points == 0 && row.time == 0.0 && row.scoringShoots == 0);
      final status = isDq ? 'DQ' : (isDnf ? 'DNF' : 'Completed');
      final ro = isDq
          ? 'Imported from portal verify page (DQ)'
          : (isDnf ? 'Imported from portal verify page (DNF)' : 'Imported from portal verify page');

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
        status: status,
        roRemark: ro,
      );
    }).toList();
  }

  Duration computeNextQueryDelay({
    required Duration responseTime,
    required bool hadResponse,
  }) {
    if (!hadResponse || responseTime > const Duration(seconds: 2)) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 2);
  }

  Future<void> delayBeforeNextRequest(Duration delay) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
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

  Future<int> detectLastShooterNumber(
    String portalUrl, {
    int startShooterNumber = 1,
    int maxAttempts = 1000,
    Duration delayBetweenChecks = Duration.zero,
    void Function(int currentShooterNumber, int? lastValidShooter, String status)? onProgress,
  }) async {
    if (startShooterNumber < 1) {
      return 0;
    }

    var low = startShooterNumber;
    var high = (startShooterNumber + maxAttempts).clamp(500, 1000000);
    var lastValidShooter = 0;

    while (low <= high) {
      final mid = low + ((high - low) ~/ 2);
      try {
        onProgress?.call(mid, lastValidShooter, 'Checking shooter $mid');
        final detail = await fetchShooterDetailFromUrl(portalUrl, mid);
        lastValidShooter = detail.shooterNumber;
        onProgress?.call(mid, lastValidShooter, detail.name);
        low = mid + 1;
      } catch (_) {
        onProgress?.call(mid, lastValidShooter, 'Shooter $mid not found');
        high = mid - 1;
      }

      if (delayBetweenChecks > Duration.zero) {
        await delayBeforeNextRequest(delayBetweenChecks);
      }
    }

    return lastValidShooter;
  }

  String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    }

    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }

    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  Future<PortalImportReport> importAllShootersFromPortal({
    required String portalUrl,
    required int startShooterNumber,
    int? endShooterNumber,
    required MatchRepository repository,
    double scaleFactor = 1.0,
    bool overwriteExistingResults = true,
    bool autoDetectEndShooter = false,
    void Function(int current, int total, String shooterName)? onProgress,
  }) async {
    final overallStopwatch = Stopwatch()..start();

    if (startShooterNumber < 1) {
      return PortalImportReport(
        success: false,
        message: 'Shooter numbers must be positive.',
      );
    }

    if (!autoDetectEndShooter) {
      if (endShooterNumber == null || endShooterNumber < 1) {
        return PortalImportReport(
          success: false,
          message: 'End shooter number must be provided when auto-detect is disabled.',
        );
      }
      if (startShooterNumber > endShooterNumber) {
        return PortalImportReport(
          success: false,
          message: 'Start shooter number must be less than or equal to the end shooter number.',
        );
      }
    }

    final totalShooters = autoDetectEndShooter ? 0 : endShooterNumber! - startShooterNumber + 1;
    var totalProcessed = 0;
    var shootersAdded = 0;
    var resultsAdded = 0;
    var resultsUpdated = 0;
    var skipped = 0;
    var lastResponseTime = Duration.zero;
    var lastValidShooter = startShooterNumber - 1;
    var shooterNumber = startShooterNumber;

    while (true) {
      final stopwatch = Stopwatch()..start();
      try {
        final currentIndex = shooterNumber - startShooterNumber + 1;
        final total = autoDetectEndShooter ? (currentIndex + 1) : totalShooters;
        onProgress?.call(currentIndex, total, 'Fetching shooter $shooterNumber');

        final detail = await fetchShooterDetailFromUrl(portalUrl, shooterNumber);
        lastResponseTime = stopwatch.elapsed;
        lastValidShooter = shooterNumber;
        onProgress?.call(currentIndex, total, detail.name);

        _debugLog('[ESS_DEBUG] bulk import: fetched shooter $shooterNumber ${detail.name}, stageRows=${detail.stageRows.length}, repositoryStages=${repository.stages.length}');

        final report = await importShooterDetail(
          detail,
          repository,
          shooterName: detail.name,
          scaleFactor: scaleFactor,
          overwriteExistingResults: overwriteExistingResults,
        );

        _debugLog('[ESS_DEBUG] bulk import: shooter $shooterNumber result success=${report.success} message=${report.message} resultsAdded=${report.resultsAdded} shootersAdded=${report.shootersAdded}');

        totalProcessed++;
        if (report.success) {
          shootersAdded += report.shootersAdded;
          resultsAdded += report.resultsAdded;
          resultsUpdated += report.resultsUpdated;
        } else {
          skipped++;
        }
      } catch (error, stackTrace) {
        lastResponseTime = stopwatch.elapsed;
        _debugLog('[ESS_DEBUG] bulk import catch: shooter $shooterNumber failed with $error');
        _debugLog('[ESS_DEBUG] bulk import stackTrace: $stackTrace');

        if (autoDetectEndShooter) {
          break;
        }

        skipped++;
        _debugLog('[ESS_DEBUG] bulk import: skipping missing shooter $shooterNumber and continuing range scan');
      }

      if (autoDetectEndShooter) {
        final delay = computeNextQueryDelay(
          responseTime: lastResponseTime,
          hadResponse: lastResponseTime > Duration.zero,
        );
        await delayBeforeNextRequest(delay);
        shooterNumber++;
        continue;
      }

      if (shooterNumber >= endShooterNumber!) {
        break;
      }

      final delay = computeNextQueryDelay(
        responseTime: lastResponseTime,
        hadResponse: lastResponseTime > Duration.zero,
      );
      await delayBeforeNextRequest(delay);
      shooterNumber++;
    }

    final importedAnyData = totalProcessed > 0 || shootersAdded > 0 || resultsAdded > 0;
    final elapsed = overallStopwatch.elapsed;
    final elapsedText = formatDuration(elapsed);

    final effectiveMessage = autoDetectEndShooter
        ? (lastValidShooter >= startShooterNumber
            ? 'Imported shooters from $startShooterNumber to $lastValidShooter. (took $elapsedText)'
            : 'No valid shooters found starting at $startShooterNumber. (took $elapsedText)')
        : (importedAnyData
            ? (skipped == 0
                ? 'Imported all shooters from $startShooterNumber to $endShooterNumber. (took $elapsedText)'
                : 'Imported ${totalProcessed - skipped} shooters from ESS match; skipped $skipped requests. (took $elapsedText)')
            : 'No valid shooter data was imported from $startShooterNumber to $endShooterNumber. (took $elapsedText)');

    return PortalImportReport(
      success: autoDetectEndShooter
          ? (lastValidShooter >= startShooterNumber && importedAnyData)
          : importedAnyData,
      message: effectiveMessage,
      shootersAdded: shootersAdded,
      resultsAdded: resultsAdded,
      resultsUpdated: resultsUpdated,
      totalProcessed: totalProcessed,
      lastShooterNumber: autoDetectEndShooter ? lastValidShooter : endShooterNumber,
      elapsedDuration: elapsed,
    );
  }

  Future<PortalImportReport> importShooterDetail(
    PortalShooterDetail detail,
    MatchRepository repository, {
    required String shooterName,
    required double scaleFactor,
    bool overwriteExistingResults = false,
  }) async {
    _debugLog('[ESS_DEBUG] importShooterDetail begin shooterName=$shooterName shooterNumber=${detail.shooterNumber} rows=${detail.stageRows.length}');
    if (repository.getShooter(shooterName) != null) {
      _debugLog('[ESS_DEBUG] importShooterDetail bail: shooter already exists name=$shooterName');
      return PortalImportReport(
        success: false,
        message: 'Shooter name "$shooterName" already exists in current match.',
      );
    }

    final importedStages = detail.stageRows.map((r) => r.stage).toSet();
    _debugLog('[ESS_DEBUG] match-setup check: importedStages=${importedStages.toList()} currentStages=${repository.stages.map((s) => s.stage).toList()}');
    if (repository.stages.isEmpty) {
      final stageMap = <int, int>{};
      for (final row in detail.stageRows) {
        final scoringShoots = row.a + row.c + row.d + row.misses;
        final current = stageMap[row.stage];
        if (current == null || scoringShoots > current) {
          stageMap[row.stage] = scoringShoots;
        }
      }
      _debugLog('[ESS_DEBUG] auto-creating stages from ESS rows: ${stageMap.entries.map((e) => '${e.key}:${e.value}').join(', ')}');
      for (final entry in stageMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
        await repository.addStage(MatchStage(stage: entry.key, scoringShoots: entry.value));
      }
    }

    final expectedStages = repository.stages.map((s) => s.stage).toSet();
    final missingStages = importedStages.where((stage) => !expectedStages.contains(stage)).toList();
    if (missingStages.isNotEmpty) {
      final stageMap = <int, int>{};
      for (final row in detail.stageRows) {
        if (!missingStages.contains(row.stage)) continue;
        final scoringShoots = row.a + row.c + row.d + row.misses;
        final current = stageMap[row.stage];
        if (current == null || scoringShoots > current) {
          stageMap[row.stage] = scoringShoots;
        }
      }
      _debugLog('[ESS_DEBUG] auto-creating missing stages from ESS rows: ${stageMap.entries.map((e) => '${e.key}:${e.value}').join(', ')}');
      for (final entry in stageMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
        await repository.addStage(MatchStage(stage: entry.key, scoringShoots: entry.value));
      }
    }

    _debugLog('[ESS_DEBUG] match-setup check complete: importedStages=${importedStages.toList()} expectedStages=${expectedStages.toList()} missingStages=$missingStages');

    var stagesAdded = 0;
    var shootersAdded = 0;
    var resultsAdded = 0;
    var resultsUpdated = 0;

    for (final row in detail.stageRows) {
      var existingStage = repository.getStage(row.stage);
      final importedScoringShoots = row.a + row.c + row.d + row.misses;
      if (existingStage == null) {
        _debugLog('[ESS_DEBUG] creating stage ${row.stage} from ESS row because it was missing');
        existingStage = MatchStage(stage: row.stage, scoringShoots: importedScoringShoots);
        await repository.addStage(existingStage);
        stagesAdded++;
      } else if (existingStage.scoringShoots != importedScoringShoots) {
        final reconciled = MatchStage(stage: row.stage, scoringShoots: importedScoringShoots);
        _debugLog('[ESS_DEBUG] reconciling stage ${row.stage} from ${existingStage.scoringShoots} to $importedScoringShoots');
        await repository.updateStage(reconciled);
      }

      final scoringShoots = repository.getStage(row.stage)!.scoringShoots;
      final isLikelyDnf = row.points == 0 && row.time == 0.0 && importedScoringShoots == 0 && row.noShoots == 0;
      if (!isLikelyDnf && importedScoringShoots != scoringShoots) {
        _debugLog('[ESS_DEBUG] importShooterDetail bail: stage ${row.stage} invalid imported=$importedScoringShoots expected=$scoringShoots stageRows=${detail.stageRows.length}');
        return PortalImportReport(
          success: false,
          message:
              'Stage ${row.stage} is invalid: A+C+D+MI = $importedScoringShoots but expected $scoringShoots scoring shoots.',
        );
      } else {
        _debugLog('[ESS_DEBUG] stage ${row.stage} validation passed: imported=$importedScoringShoots expected=$scoringShoots isLikelyDnf=$isLikelyDnf');
      }
    }

    _debugLog('[ESS_DEBUG] stage validation passed for shooter $shooterName; proceeding to repository write');

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

    _debugLog('[ESS_DEBUG] writing shooter $shooterName to repository with ${detail.stageRows.length} rows');
    await repository.addShooter(
      Shooter(
        name: shooterName,
        scaleFactor: scaleFactor,
        division: detail.division,
        shooterClass: detail.shooterClass,
        category: detail.category,
      ),
    );
    shootersAdded++;

    _debugLog('[ESS_DEBUG] repository now has shooters=${repository.shooters.length} results=${repository.results.length} stages=${repository.stages.length}');

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
