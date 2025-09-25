
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/stage_input_viewmodel.dart';

class StageInputView extends StatelessWidget {
  const StageInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StageInputViewModel>(
      builder: (context, vm, _) => _StageInputViewBody(vm: vm),
    );
  }
}

class _StageInputViewBody extends StatefulWidget {
  final StageInputViewModel vm;
  const _StageInputViewBody({required this.vm});

  @override
  State<_StageInputViewBody> createState() => _StageInputViewBodyState();
}

class _StageInputViewBodyState extends State<_StageInputViewBody> {
  final _timeController = TextEditingController();
  final _aController = TextEditingController();
  final _cController = TextEditingController();
  final _dController = TextEditingController();
  final _missesController = TextEditingController();
  final _noShootsController = TextEditingController();
  final _procErrorsController = TextEditingController();

  String? _editingKey;

  @override
  void dispose() {
    _timeController.dispose();
    _aController.dispose();
    _cController.dispose();
    _dController.dispose();
    _missesController.dispose();
    _noShootsController.dispose();
    _procErrorsController.dispose();
    super.dispose();
  }

  void _refreshFields() {
    _timeController.text = widget.vm.time.toString();
    _aController.text = widget.vm.a.toString();
    _cController.text = widget.vm.c.toString();
    _dController.text = widget.vm.d.toString();
    _missesController.text = widget.vm.misses.toString();
    _noShootsController.text = widget.vm.noShoots.toString();
    _procErrorsController.text = widget.vm.procErrors.toString();
  }

  @override
  Widget build(BuildContext context) {
  final repo = widget.vm.repository;
  final results = repo.results;
  final stages = repo.stages;
  final shooters = repo.shooters;
  final isValid = widget.vm.isValid;
  final validationError = widget.vm.validationError;
    return Scaffold(
      appBar: AppBar(title: const Text('Stage Input')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stages.isEmpty || shooters.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Please add at least one stage and one shooter first.',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ...existing code for selectors and fields...
                          DropdownButtonFormField<int>(
                            key: const Key('stageSelector'),
                            value: stages.any((s) => s.stage == widget.vm.selectedStage)
                                ? widget.vm.selectedStage
                                : null,
                            items: stages
                                .map((s) => DropdownMenuItem(
                                      value: s.stage,
                                      child: Text('Stage ${s.stage}'),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => widget.vm.selectStage(v));
                            },
                            decoration: const InputDecoration(
                              labelText: 'Stage',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: const Key('shooterSelector'),
                            value: shooters.any((s) => s.name == widget.vm.selectedShooter)
                                ? widget.vm.selectedShooter
                                : null,
                            items: shooters
                                .map((s) => DropdownMenuItem(
                                      value: s.name,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => widget.vm.selectShooter(v));
                            },
                            decoration: const InputDecoration(
                              labelText: 'Shooter',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ...existing code for all input fields and submit...
                          TextField(
                            key: const Key('timeField'),
                            controller: _timeController,
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              prefixIcon: Icon(Icons.timer),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) {
                              final t = double.tryParse(v) ?? 0.0;
                              setState(() => widget.vm.time = t);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('aField'),
                            controller: _aController,
                            decoration: const InputDecoration(
                              labelText: 'A',
                              prefixIcon: Icon(Icons.looks_one),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 0;
                              setState(() => widget.vm.a = n);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('cField'),
                            controller: _cController,
                            decoration: const InputDecoration(
                              labelText: 'C',
                              prefixIcon: Icon(Icons.looks_two),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 0;
                              setState(() => widget.vm.c = n);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('dField'),
                            controller: _dController,
                            decoration: const InputDecoration(
                              labelText: 'D',
                              prefixIcon: Icon(Icons.looks_3),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 0;
                              setState(() => widget.vm.d = n);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('missesField'),
                                  controller: _missesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Misses',
                                    prefixIcon: Icon(Icons.close),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    final n = int.tryParse(v) ?? 0;
                                    setState(() => widget.vm.misses = n);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  key: const Key('noShootsField'),
                                  controller: _noShootsController,
                                  decoration: const InputDecoration(
                                    labelText: 'No Shoots',
                                    prefixIcon: Icon(Icons.block),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    final n = int.tryParse(v) ?? 0;
                                    setState(() => widget.vm.noShoots = n);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('procErrorsField'),
                                  controller: _procErrorsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Procedure Errors',
                                    prefixIcon: Icon(Icons.error),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    final n = int.tryParse(v) ?? 0;
                                    setState(() => widget.vm.procErrors = n);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('submitButton'),
                                  onPressed: isValid
                                      ? () {
                                          setState(() {
                                            widget.vm.submit();
                                            _editingKey = null;
                                            _refreshFields();
                                          });
                                        }
                                      : null,
                                  child: Text(_editingKey == null ? 'Submit' : 'Update'),
                                ),
                              ),
                            ],
                          ),
                          if (validationError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(validationError, style: const TextStyle(color: Colors.red)),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('Hit Factor: ${widget.vm.hitFactor.toStringAsFixed(2)}'),
                              const SizedBox(width: 16),
                              Text('Adjusted: ${widget.vm.adjustedHitFactor.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  key: const Key('resultsList'),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final r = results[idx];
                    return Card(
                      elevation: 1,
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(r.shooter),
                        subtitle: Text('Stage: ${r.stage}, Time: ${r.time}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('editResult-${r.stage}-${r.shooter}'),
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  widget.vm.selectStage(r.stage);
                                  widget.vm.selectShooter(r.shooter);
                                  _editingKey = '${r.stage}-${r.shooter}';
                                  _refreshFields();
                                });
                              },
                            ),
                            IconButton(
                              key: Key('removeResult-${r.stage}-${r.shooter}'),
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  widget.vm.selectStage(r.stage);
                                  widget.vm.selectShooter(r.shooter);
                                  widget.vm.remove();
                                  _editingKey = null;
                                  _refreshFields();
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
          ],
        ),
      ),
    );
  }
}
