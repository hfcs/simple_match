import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart';
import '../viewmodel/match_setup_viewmodel.dart';
import '../repository/match_repository.dart';

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
    final repo = Provider.of<MatchRepository>(context);
    final stages = repo.stages;
    if (kDebugMode) {
      // Helpful debug trace for widget tests when UI does not update as expected
      // (keeps output short and localized)
      // ignore: avoid_print
      print('DBG: MatchSetupView.build stages.len=${stages.length}');
    }
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
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_editingStage == null)
                          ElevatedButton.icon(
                            key: const Key('addStageButton'),
                            icon: const Icon(Icons.add),
                              onPressed: () async {
                                final stage = int.tryParse(_stageController.text);
                                final shoots = int.tryParse(
                                  _shootsController.text,
                                );
                                if (stage == null || shoots == null) {
                                  setState(() => _error = 'Invalid input.');
                                  return;
                                }

                                // If user entered more than 32 scoring shoots, ask for confirmation
                                if (shoots > 32) {
                                  final confirmed = await showDialog<bool?>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Large shoot count'),
                                      content: Text('Scoring shoots > 32 is outside standard IPSC scoring. Proceed with $shoots shoots?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Proceed')),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) {
                                    setState(() => _error = null);
                                    return;
                                  }
                                }

                                try {
                                  final err = await vm.addStage(stage, shoots, allowMoreThan32: true);
                                  if (kDebugMode) {
                                    // ignore: avoid_print
                                    print('DBG: MatchSetupView.addStage returned err=$err');
                                  }
                                  setState(() => _error = err);
                                  if (err == null) {
                                    _stageController.clear();
                                    _shootsController.clear();
                                  }
                                } catch (e) {
                                  if (kDebugMode) print('DBG: MatchSetupView.addStage threw $e');
                                  setState(() => _error = e.toString());
                                }
                              },
                            label: const Text('Add Stage'),
                          )
                        else ...[
                          ElevatedButton.icon(
                            key: const Key('confirmEditButton'),
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              final shoots = int.tryParse(
                                _shootsController.text,
                              );
                              if (shoots == null) {
                                setState(() => _error = 'Invalid input.');
                                return;
                              }

                              if (shoots > 32) {
                                final confirmed = await showDialog<bool?>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Large shoot count'),
                                    content: Text('Scoring shoots > 32 is outside standard IPSC scoring. Proceed with $shoots shoots?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Proceed')),
                                    ],
                                  ),
                                );
                                if (confirmed != true) {
                                  setState(() => _error = null);
                                  return;
                                }
                              }

                              try {
                                final err = await vm.editStage(_editingStage!, shoots, allowMoreThan32: true);
                                if (kDebugMode) {
                                  // ignore: avoid_print
                                  print('DBG: MatchSetupView.editStage returned err=$err');
                                }
                                setState(() => _error = err);
                                if (err == null) {
                                  setState(() => _editingStage = null);
                                  _stageController.clear();
                                  _shootsController.clear();
                                }
                              } catch (e) {
                                if (kDebugMode) print('DBG: MatchSetupView.editStage threw $e');
                                setState(() => _error = e.toString());
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
            const Text(
              'Stages:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                      title: Text(
                        'Stage ${s.stage}: ${s.scoringShoots} shoots',
                      ),
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
                                _shootsController.text = s.scoringShoots
                                    .toString();
                                _error = null;
                              });
                            },
                          ),
                          IconButton(
                            key: Key('removeStage-${s.stage}'),
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove Stage'),
                                  content: Text('Remove stage ${s.stage}? This will delete any associated results.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                vm.removeStage(s.stage);
                                setState(() {
                                  if (_editingStage == s.stage) {
                                    _editingStage = null;
                                    _stageController.clear();
                                    _shootsController.clear();
                                  }
                                });
                              }
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
