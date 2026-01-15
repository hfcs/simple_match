import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../repository/match_repository.dart';
import '../viewmodel/overall_result_viewmodel.dart';
import '../models/team_game.dart';
import '../models/shooter.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Use the html conditional to ensure the web implementation is selected for web
// builds. The previous conditional used `dart.library.io` which can cause the
// non-web implementation (which throws UnsupportedError) to be chosen in some
// build scenarios. Explicitly prefer the non-web default and swap in the
// web-specific file when `dart.library.html` is available.
import 'non_web_pdf_utils.dart' if (dart.library.html) 'web_pdf_utils.dart';

class OverallResultView extends StatelessWidget {
  const OverallResultView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get repository and viewmodel
    final repo = Provider.of<MatchRepository>(context, listen: false);
    final viewModel = OverallResultViewModel(repo);
    final results = viewModel.getOverallResults();
    final stages = repo.stages;
    final shooters = repo.shooters;
    final allResults = repo.results;
    final teamGame = repo.teamGame;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Result'),
        actions: results.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export overall results to PDF',
                  onPressed: () async {
                    // PDF export button pressed
                    try {
                      final pdf = await buildOverallResultPdf(
                        results: results,
                        stages: stages,
                        shooters: shooters,
                        allResults: allResults,
                        teamGame: teamGame,
                      );
                      // PDF generated successfully

                      if (kIsWeb) {
                        // Web-specific logic
                        await WebPdfUtils.downloadPdf(pdf);
                      } else {
                        // Non-web platform logic
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdf.save(),
                        );
                        // PDF sent to printer
                      }
                    } catch (e) {
                      // Error during PDF export: $e
                    }
                  },
                ),
              ]
            : [],
      ),
      body: results.isEmpty
          ? const Center(child: Text('No results yet.'))
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                ...List.generate(results.length, (i) {
                  final r = results[i];
                  return Column(children: [
                    ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(r.name),
                      trailing: Text(r.totalPoints.toStringAsFixed(2)),
                    ),
                    const Divider(),
                  ]);
                }),
                if (teamGame != null && teamGame.mode != 'off' && teamGame.teams.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Team Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          // compute team scores from shooter totals
                          final shooterTotals = {for (final r in results) r.name: r.totalPoints};
                          final teamRows = teamGame.teams.map((t) {
                            final members = (t.members as List).cast<String>();
                            final memberTotals = members.map((m) => shooterTotals[m] ?? 0.0).toList();
                            double score = 0.0;
                            if (teamGame.mode == 'average') {
                              score = memberTotals.isNotEmpty ? memberTotals.reduce((a, b) => a + b) / memberTotals.length : 0.0;
                            } else {
                              final n = teamGame.topCount <= 0 ? memberTotals.length : teamGame.topCount;
                              memberTotals.sort((a, b) => b.compareTo(a));
                              score = memberTotals.take(n).fold<double>(0.0, (p, e) => p + e);
                            }
                            return {'team': t, 'score': score, 'members': members};
                          }).toList();
                          teamRows.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
                          return Column(children: [
                            ...List.generate(teamRows.length, (i) {
                              final row = teamRows[i];
                              final t = row['team'];
                              return ListTile(
                                leading: CircleAvatar(child: Text('${i + 1}')),
                                title: Text((t as dynamic).name as String),
                                subtitle: Text((row['members'] as List).join(', ')),
                                trailing: Text((row['score'] as double).toStringAsFixed(2)),
                              );
                            }),
                          ]);
                        })
                      ]),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

Future<pw.Document> buildOverallResultPdf({
  required List results,
  required List stages,
  required List shooters,
  required List allResults,
  TeamGame? teamGame,
}) async {
  final fontData = await rootBundle.load('assets/fonts/NotoSerifHK-wght.ttf');
  final font = pw.Font.ttf(fontData);
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        italic: font,
        boldItalic: font,
      ),
      build: (context) {
        final widgets = <pw.Widget>[];
        // Overall ranking table
        widgets.add(
          pw.Text(
            'Overall Shooter Results',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 16));
        widgets.add(
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Rank',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: font,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Name',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: font,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Match Points (after scaling)',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: font,
                      ),
                    ),
                  ),
                ],
              ),
              ...List.generate(results.length, (i) {
                final r = results[i];
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(font: font),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r.name, style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        r.totalPoints.toStringAsFixed(2),
                        style: pw.TextStyle(font: font),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 24));

        // Team ranking table (only if enabled)
        if (teamGame != null && teamGame.mode != 'off' && teamGame.teams.isNotEmpty) {
          // Build shooter totals map from results
          final Map<String, double> shooterTotals = {};
          for (final r in results) {
            try {
              shooterTotals[r.name] = (r.totalPoints as double);
            } catch (_) {
              shooterTotals[r.name] = (r.totalPoints as double? ?? 0.0);
            }
          }

          List<Map<String, dynamic>> teamRows = [];
          for (final t in teamGame.teams) {
            final members = (t.members as List).cast<String>();
            final memberTotals = members.map((m) => shooterTotals[m] ?? 0.0).toList();
            double score = 0.0;
            if (teamGame.mode == 'average') {
              score = memberTotals.isNotEmpty ? memberTotals.reduce((a, b) => a + b) / memberTotals.length : 0.0;
            } else if (teamGame.mode == 'top') {
              final n = teamGame.topCount <= 0 ? memberTotals.length : teamGame.topCount;
              memberTotals.sort((a, b) => b.compareTo(a));
              final take = memberTotals.take(n);
              score = take.fold<double>(0.0, (p, e) => p + e);
            }
            teamRows.add({'team': t, 'score': score, 'members': members});
          }
          teamRows.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

          widgets.add(pw.Text('Team Results', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font)));
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Rank', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Team', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Members', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
              ]),
              ...List.generate(teamRows.length, (i) {
                final row = teamRows[i];
                final t = row['team'];
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${i + 1}', style: pw.TextStyle(font: font))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((t as dynamic).name as String, style: pw.TextStyle(font: font))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((row['score'] as double).toStringAsFixed(2), style: pw.TextStyle(font: font))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((row['members'] as List).join(', '), style: pw.TextStyle(font: font))),
                ]);
              }),
            ],
          ));
          

          widgets.add(pw.SizedBox(height: 16));
        }

        // Per-stage results
        for (final stage in stages) {
          widgets.add(
            pw.Text(
              'Stage ${stage.stage} Results',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(),
              // Use explicit column width weights so the Match Pt column
              // does not consume excessive width. Name gets extra space
              // (weight 3) while other numeric columns get smaller equal
              // weights. This makes A/C/D columns wide enough for 3 digits.
              columnWidths: {
                0: pw.FlexColumnWidth(3), // Name (wide)
                1: pw.FlexColumnWidth(1), // Raw HF
                2: pw.FlexColumnWidth(2), // Scaled HF (wider)
                3: pw.FlexColumnWidth(2.5), // Match Pt (wider)
                4: pw.FlexColumnWidth(1), // Time
                // Narrow numeric columns: reserve just enough for 2-digit values
                5: pw.FlexColumnWidth(0.5), // A
                6: pw.FlexColumnWidth(0.5), // C
                7: pw.FlexColumnWidth(0.5), // D
                8: pw.FlexColumnWidth(0.5), // Misses
                9: pw.FlexColumnWidth(0.5), // No Shoots
                10: pw.FlexColumnWidth(0.5), // Proc Err
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Name',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Raw HF',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Scaled HF',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Match Pt',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Time',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'A',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'C',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'D',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Misses',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'No Shoots',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Proc Err',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ),
                  ],
                ),
                ...() {
                  final stageResults = allResults
                      .where((r) => r.stage == stage.stage)
                      .toList();
                  // Calculate max adjusted hit factor for this stage to compute adjusted match points
                  final Map<String, double> adjHitFactors = {};
                  for (final r in stageResults) {
                    final shooter = shooters.firstWhere(
                      (s) => s.name == r.shooter,
                      orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0),
                    );
                    adjHitFactors[r.shooter] = r.adjustedHitFactor(
                      shooter.scaleFactor,
                    );
                  }
                  final maxAdjHitFactor = adjHitFactors.values.isNotEmpty
                      ? adjHitFactors.values.reduce((a, b) => a > b ? a : b)
                      : 0.0;

                  // Create list of results with calculated match points for sorting
                  final resultRows = stageResults.map((r) {
                    final shooter = shooters.firstWhere(
                      (s) => s.name == r.shooter,
                      orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0),
                    );
                    final rawHF = r.hitFactor;
                    final scaledHF = r.adjustedHitFactor(shooter.scaleFactor);
                    final adjustedMatchPoint = maxAdjHitFactor > 0
                        ? (scaledHF / maxAdjHitFactor) * stage.scoringShoots * 5
                        : 0.0;
                    return {
                      'result': r,
                      'shooter': shooter,
                      'rawHF': rawHF,
                      'scaledHF': scaledHF,
                      'adjustedMatchPoint': adjustedMatchPoint,
                    };
                  }).toList();

                  // Sort by adjusted match point (highest first)
                  resultRows.sort(
                    (a, b) => (b['adjustedMatchPoint'] as double).compareTo(
                      a['adjustedMatchPoint'] as double,
                    ),
                  );

                  return resultRows.map((row) {
                    final r = row['result'];
                    final rawHF = row['rawHF'] as double;
                    final scaledHF = row['scaledHF'] as double;
                    final adjustedMatchPoint =
                        row['adjustedMatchPoint'] as double;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.shooter,
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            rawHF.toStringAsFixed(2),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            scaledHF.toStringAsFixed(2),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            adjustedMatchPoint.toStringAsFixed(2),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.time.toStringAsFixed(2),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.a.toString(),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.c.toString(),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.d.toString(),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.misses.toString(),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.noShoots.toString(),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            r.procedureErrors.toString(),
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                      ],
                    );
                  });
                }(),
              ],
            ),
          );
          // Per-stage team breakdown (only if team scoring enabled)
          if (teamGame != null && teamGame.mode != 'off' && teamGame.teams.isNotEmpty) {
            final stageResults = allResults.where((r) => r.stage == stage.stage).toList();
            final Map<String, double> adjHitFactors = {};
            for (final r in stageResults) {
              final shooter = shooters.firstWhere((s) => s.name == r.shooter, orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0));
              adjHitFactors[r.shooter] = r.adjustedHitFactor(shooter.scaleFactor);
            }
            final maxAdjHitFactor = adjHitFactors.values.isNotEmpty ? adjHitFactors.values.reduce((a, b) => a > b ? a : b) : 0.0;
            final Map<String, double> shooterStagePoints = {};
            for (final r in stageResults) {
              final shooter = shooters.firstWhere((s) => s.name == r.shooter, orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0));
              final scaledHF = r.adjustedHitFactor(shooter.scaleFactor);
              final adjustedMatchPoint = maxAdjHitFactor > 0 ? (scaledHF / maxAdjHitFactor) * stage.scoringShoots * 5 : 0.0;
              shooterStagePoints[r.shooter] = adjustedMatchPoint;
            }

            List<Map<String, dynamic>> perStageTeamRows = [];
            for (final t in teamGame.teams) {
              final members = (t.members as List).cast<String>();
              final memberPoints = members.map((m) => shooterStagePoints[m] ?? 0.0).toList();
              double score = 0.0;
              if (teamGame.mode == 'average') {
                score = memberPoints.isNotEmpty ? memberPoints.reduce((a, b) => a + b) / memberPoints.length : 0.0;
              } else if (teamGame.mode == 'top') {
                final n = teamGame.topCount <= 0 ? memberPoints.length : teamGame.topCount;
                memberPoints.sort((a, b) => b.compareTo(a));
                score = memberPoints.take(n).fold<double>(0.0, (p, e) => p + e);
              }
              perStageTeamRows.add({'team': t, 'score': score, 'members': members});
            }
            perStageTeamRows.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

            widgets.add(pw.SizedBox(height: 8));
            widgets.add(pw.Text('Team Results (Stage ${stage.stage})', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Rank', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Team', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Stage Points', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                ]),
                ...List.generate(perStageTeamRows.length, (i) {
                  final row = perStageTeamRows[i];
                  final t = row['team'];
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${i + 1}', style: pw.TextStyle(font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((t as dynamic).name as String, style: pw.TextStyle(font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((row['score'] as double).toStringAsFixed(2), style: pw.TextStyle(font: font))),
                  ]);
                }),
              ],
            ));
            widgets.add(pw.SizedBox(height: 8));
          }
          widgets.add(pw.SizedBox(height: 16));
        }
        return widgets;
      },
    ),
  );
  return pdf;
}
