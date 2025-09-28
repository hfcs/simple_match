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
                                  // Table header
                                  Row(
                                    children: const [
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('Raw HF', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('Scaled HF', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('C', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('D', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('Misses', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('No Shoots', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                      SizedBox(width: 8),
                                      Expanded(child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text('Proc Err', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )),
                                    ],
                                  ),
                                  const Divider(),
                                  ...ranks.map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(e.name)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.hitFactor.toStringAsFixed(2))),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.adjustedHitFactor.toStringAsFixed(2))),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.time.toStringAsFixed(2))),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.a.toString())),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.c.toString())),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.d.toString())),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.misses.toString())),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.noShoots.toString())),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.procedureErrors.toString())),
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
}
