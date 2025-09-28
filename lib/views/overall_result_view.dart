
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../viewmodel/overall_result_viewmodel.dart';
import '../repository/match_repository.dart';
import '../models/shooter.dart';
class OverallResultView extends StatelessWidget {
  const OverallResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OverallResultViewModel>(
      builder: (context, vm, _) {
        final results = vm.getOverallResults();
        final repo = Provider.of<MatchRepository>(context, listen: false);
        final stages = repo.stages;
        final shooters = repo.shooters;
        final allResults = repo.results;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Overall Result'),
            actions: [
              if (results.isNotEmpty)
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
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Shooter Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('No results yet.'))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final r = results[i];
                            return Card(
                              elevation: 1,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text('${i + 1}', style: const TextStyle(color: Colors.black)),
                                ),
                                title: Text(r.name),
                                subtitle: const Text('Total Adjusted Points'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emoji_events, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(r.totalPoints.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



Future<pw.Document> buildOverallResultPdf({
  required List results,
  required List stages,
  required List shooters,
  required List allResults,
}) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      build: (context) {
        final widgets = <pw.Widget>[];
        // Overall ranking table
        widgets.add(
          pw.Text('Overall Shooter Results', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
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
                    child: pw.Text('Rank', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Total Adjusted Points', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...List.generate(results.length, (i) {
                final r = results[i];
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('${i + 1}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r.name),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r.totalPoints.toStringAsFixed(2)),
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
            pw.Text('Stage ${stage.stage} Results', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          );
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Raw HF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Scaled HF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('C', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('D', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Misses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No Shoots', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Proc Err', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...allResults.where((r) => r.stage == stage.stage).map((r) {
                  final shooter = shooters.firstWhere((s) => s.name == r.shooter, orElse: () => Shooter(name: r.shooter, scaleFactor: 1.0));
                  final rawHF = r.hitFactor;
                  final scaledHF = r.adjustedHitFactor(shooter.scaleFactor);
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.shooter)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rawHF.toStringAsFixed(2))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(scaledHF.toStringAsFixed(2))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.time.toStringAsFixed(2))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.a.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.c.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.d.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.misses.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.noShoots.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r.procedureErrors.toString())),
                    ],
                  );
                }).toList(),
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
