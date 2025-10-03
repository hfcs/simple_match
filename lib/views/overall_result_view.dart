
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../repository/match_repository.dart';
import '../viewmodel/overall_result_viewmodel.dart';
import '../models/shooter.dart';
import 'package:printing/printing.dart';
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
                    final pdf = await buildOverallResultPdf(
                      results: results,
                      stages: stages,
                      shooters: shooters,
                      allResults: allResults,
                    );
                    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
          pw.Text('Overall Shooter Results', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: font)),
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
                    child: pw.Text('Rank', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Total Adjusted Points', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                  ),
                ],
              ),
              ...List.generate(results.length, (i) {
                final r = results[i];
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('${i + 1}', style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r.name, style: pw.TextStyle(font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r.totalPoints.toStringAsFixed(2), style: pw.TextStyle(font: font)),
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
            pw.Text('Stage ${stage.stage} Results', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: font)),
          );
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Raw HF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Scaled HF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('C', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('D', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Misses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No Shoots', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Proc Err', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))),
                  ],
                ),
                ...allResults.where((r) => r.stage == stage.stage).map((r) {
                  final shooter = shooters.firstWhere((s) => s.name == r.shooter, orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0));
                  final rawHF = r.hitFactor;
                  final scaledHF = r.adjustedHitFactor(shooter.scaleFactor);
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.shooter, style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rawHF.toStringAsFixed(2), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(scaledHF.toStringAsFixed(2), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.time.toStringAsFixed(2), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.a.toString(), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.c.toString(), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.d.toString(), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.misses.toString(), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.noShoots.toString(), style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.procedureErrors.toString(), style: pw.TextStyle(font: font))),
                    ],
                  );
                }),
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


