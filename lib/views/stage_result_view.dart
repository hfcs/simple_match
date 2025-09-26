import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../viewmodel/stage_result_viewmodel.dart';

class StageResultView extends StatelessWidget {
  final StageResultViewModel viewModel;
  const StageResultView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: StageResultViewBody(),
    );
  }
}



class StageResultViewBody extends StatefulWidget {
  const StageResultViewBody({super.key});
  @override
  State<StageResultViewBody> createState() => StageResultViewBodyState();
}

class StageResultViewBodyState extends State<StageResultViewBody> {
  int? _selectedStage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = Provider.of<StageResultViewModel>(context, listen: false);
    if (_selectedStage == null && vm.stages.isNotEmpty) {
      setState(() {
        _selectedStage = vm.stages.first.stage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StageResultViewModel>(context);
    final stageRanks = vm.getStageRanks();
    final stages = vm.stages;
    final selected = _selectedStage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage Result'),
        actions: [
          if (stageRanks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export all stages to PDF',
              onPressed: () async {
                final pdf = await StageResultViewBodyState.buildAllStagesResultPdf(stageRanks);
                await Printing.layoutPdf(onLayout: (format) async => pdf.save());
              },
            ),
        ],
      ),
      body: stages.isEmpty
          ? const Center(child: Text('No stages available.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<int>(
                        initialValue: selected,
                    items: stages
                        .map((s) => DropdownMenuItem(
                              value: s.stage,
                              child: Text('Stage ${s.stage}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStage = v),
                    decoration: const InputDecoration(
                      labelText: 'Select Stage',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final ranks = selected != null ? stageRanks[selected] ?? [] : [];
                      if (ranks.isEmpty) {
                        return const Center(child: Text('No results for this stage.'));
                      }
                      return ListView(
                        children: [
                          Card(
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stage $selected', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: const [
                                      Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 12),
                                      Expanded(child: Text('Hit Factor', style: TextStyle(fontWeight: FontWeight.bold))),
                                      SizedBox(width: 12),
                                      Expanded(child: Text('Adjusted', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                  const Divider(),
                                  ...ranks.asMap().entries.map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(e.value.name)),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(e.value.hitFactor.toStringAsFixed(2))),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(e.value.adjustedHitFactor.toStringAsFixed(2))),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  static Future<pw.Document> buildAllStagesResultPdf(Map<int, List> stageRanks) async {
    final pdf = pw.Document();
    stageRanks.forEach((stage, ranks) {
      if (ranks.isEmpty) return;
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Stage $stage Results', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Hit Factor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Adjusted', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...ranks.map<pw.TableRow>((e) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(e.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(e.hitFactor.toStringAsFixed(2)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(e.adjustedHitFactor.toStringAsFixed(2)),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
    return pdf;
  }
}
