import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../repository/match_repository.dart';
import '../viewmodel/overall_result_viewmodel.dart';
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
          : ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final r = results[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(r.name),
                  trailing: Text(r.totalPoints.toStringAsFixed(2)),
                );
              },
            ),
    );
  }
}

Future<pw.Document> buildOverallResultPdf({
  required List results,
  required List stages,
  required List shooters,
  required List allResults,
}) async {
  final fontData = await rootBundle.load('assets/fonts/NotoSerifHK[wght].ttf');
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
                        'Match Pt (After Scaling)',
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
          widgets.add(pw.SizedBox(height: 16));
        }
        return widgets;
      },
    ),
  );
  return pdf;
}
