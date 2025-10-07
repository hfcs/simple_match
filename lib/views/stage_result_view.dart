import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// PDF export removed; no longer needed here.
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
  // Helper for vertical rule between columns
  Widget _tableCellWithRule(Widget child) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Container(
          width: 1,
          height: 32,
          color: Colors.grey.shade400,
          margin: const EdgeInsets.symmetric(horizontal: 2),
        ),
      ],
    );
  }
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
                      // Column widths in characters: Name: 10, Raw HF: 5, Scaled HF: 5, Time: 5, A: 2, C: 2, D: 2, Misses: 2, No Shoots: 2, Procedure Errors: 2
                      // Approximate width per char: 10px (depends on font, but for mobile, use tightest reasonable)
                      // Use SizedBox for each column, and a slightly larger font size that fits all columns
                      final double charWidth = 10.0;
                      final double fontSize = 15.0; // Largest that fits all columns on mobile
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Card(
                              margin: const EdgeInsets.all(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Stage $selected', style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 8),
                                    // Table header
                                    Row(
                                      key: const Key('stageResultTableHeader'),
                                      children: [
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 10,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 5,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('Raw HF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 5,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('Scaled HF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 5,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('Match Pt (After Scaling)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 5,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 2,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 2,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 2,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 2,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('Misses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        _tableCellWithRule(
                                          SizedBox(
                                            width: charWidth * 2,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text('No Shoots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            ),
                                          ),
                                        ),
                                        // Last column, no rule
                                        SizedBox(
                                          width: charWidth * 2,
                                          child: RotatedBox(
                                            quarterTurns: 3,
                                            child: Text('Proc Err', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    ...ranks.map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 10,
                                                  child: Text(e.name, style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 5,
                                                  child: Text(e.hitFactor.toStringAsFixed(2), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 5,
                                                  child: Text(e.adjustedHitFactor.toStringAsFixed(2), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 5,
                                                  child: Text(e.adjustedMatchPoint.toStringAsFixed(2), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 5,
                                                  child: Text(e.time.toStringAsFixed(2), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 2,
                                                  child: Text(e.a.toString(), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 2,
                                                  child: Text(e.c.toString(), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 2,
                                                  child: Text(e.d.toString(), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 2,
                                                  child: Text(e.misses.toString(), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              _tableCellWithRule(
                                                SizedBox(
                                                  width: charWidth * 2,
                                                  child: Text(e.noShoots.toString(), style: TextStyle(fontSize: fontSize)),
                                                ),
                                              ),
                                              // Last column, no rule
                                              SizedBox(
                                                width: charWidth * 2,
                                                child: Text(e.procedureErrors.toString(), style: TextStyle(fontSize: fontSize)),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
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
}
