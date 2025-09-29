import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../viewmodel/match_setup_viewmodel.dart';

class MatchSetupView extends StatefulWidget {
  const MatchSetupView({super.key});

  @override
  State<MatchSetupView> createState() => _MatchSetupViewState();
}

class _MatchSetupViewState extends State<MatchSetupView> {
  final _stageController = TextEditingController();
  final _shootsController = TextEditingController();
  String? _error;
  int? _editingStage;

  @override
  void dispose() {
    _stageController.dispose();
    _shootsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MatchSetupViewModel>(context);
    final stages = vm.repository.stages;
    return Scaffold(
      appBar: AppBar(title: const Text('Match Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      key: const Key('stageField'),
                      controller: _stageController,
                      decoration: const InputDecoration(
                        labelText: 'Stage (1-30)',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: _editingStage == null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('scoringShootsField'),
                      controller: _shootsController,
                      decoration: const InputDecoration(
                        labelText: 'Scoring Shoots (1-32)',
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_editingStage == null)
                          ElevatedButton.icon(
                            key: const Key('addStageButton'),
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final stage = int.tryParse(_stageController.text);
                              final shoots = int.tryParse(_shootsController.text);
                              final err = (stage == null || shoots == null)
                                  ? 'Invalid input.'
                                  : vm.addStage(stage, shoots);
                              setState(() => _error = err);
                              if (err == null) {
                                _stageController.clear();
                                _shootsController.clear();
                              }
                            },
                            label: const Text('Add Stage'),
                          )
                        else ...[
                          ElevatedButton.icon(
                            key: const Key('confirmEditButton'),
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              final shoots = int.tryParse(_shootsController.text);
                              final err = (shoots == null)
                                  ? 'Invalid input.'
                                  : vm.editStage(_editingStage!, shoots);
                              setState(() => _error = err);
                              if (err == null) {
                                setState(() => _editingStage = null);
                                _stageController.clear();
                                _shootsController.clear();
                              }
                            },
                            label: const Text('Confirm Edit'),
                          ),
                          const SizedBox(width: 8),
                          // This branch is reachable and testable (see widget test: can enter edit mode and cancel)
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _editingStage = null);
                              _stageController.clear();
                              _shootsController.clear();
                              _error = null;
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Stages:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: stages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final s = stages[idx];
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.flag),
                      title: Text('Stage ${s.stage}: ${s.scoringShoots} shoots'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('editStage-${s.stage}'),
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                _editingStage = s.stage;
                                _stageController.text = s.stage.toString();
                                _shootsController.text = s.scoringShoots.toString();
                                _error = null;
                              });
                            },
                          ),
                          IconButton(
                            key: Key('removeStage-${s.stage}'),
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              vm.removeStage(s.stage);
                              setState(() {
                                if (_editingStage == s.stage) {
                                  _editingStage = null;
                                  _stageController.clear();
                                  _shootsController.clear();
                                }
                              });
                            },
                          ),
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
  }
}
