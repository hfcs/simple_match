import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/stage_result_viewmodel.dart';

class StageResultView extends StatelessWidget {
  final StageResultViewModel viewModel;
  const StageResultView({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _StageResultViewBody(),
    );
  }
}

class _StageResultViewBody extends StatefulWidget {
  @override
  State<_StageResultViewBody> createState() => _StageResultViewBodyState();
}

class _StageResultViewBodyState extends State<_StageResultViewBody> {
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
      appBar: AppBar(title: const Text('Stage Result')),
      body: stages.isEmpty
          ? const Center(child: Text('No stages available.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<int>(
                    value: selected,
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
}
