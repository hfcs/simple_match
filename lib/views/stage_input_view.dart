
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
    _timeController.text = widget.vm.time == 0.0 ? '' : widget.vm.time.toString();
    _aController.text = widget.vm.a == 0 ? '' : widget.vm.a.toString();
    _cController.text = widget.vm.c == 0 ? '' : widget.vm.c.toString();
    _dController.text = widget.vm.d == 0 ? '' : widget.vm.d.toString();
    _missesController.text = widget.vm.misses == 0 ? '' : widget.vm.misses.toString();
    _noShootsController.text = widget.vm.noShoots == 0 ? '' : widget.vm.noShoots.toString();
    _procErrorsController.text = widget.vm.procErrors == 0 ? '' : widget.vm.procErrors.toString();
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
                              if (v != null) {
                                setState(() {
                                  widget.vm.selectStage(v);
                                  _refreshFields();
                                });
                              }
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
                              if (v != null) {
                                setState(() {
                                  widget.vm.selectShooter(v);
                                  _refreshFields();
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Shooter',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Time
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final t = double.tryParse(_timeController.text) ?? 0.0;
                                  final newVal = (t - 0.01).clamp(0.0, 999.99);
                                  _timeController.text = newVal.toStringAsFixed(2);
                                  setState(() => widget.vm.time = newVal);
                                },
                              ),
                              Expanded(
                                child: TextField(
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final t = double.tryParse(_timeController.text) ?? 0.0;
                                  final newVal = (t + 0.01).clamp(0.0, 999.99);
                                  _timeController.text = newVal.toStringAsFixed(2);
                                  setState(() => widget.vm.time = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // A
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final n = int.tryParse(_aController.text) ?? 0;
                                  final newVal = (n - 1).clamp(0, 999);
                                  _aController.text = newVal.toString();
                                  setState(() => widget.vm.a = newVal);
                                },
                              ),
                              Expanded(
                                child: TextField(
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final n = int.tryParse(_aController.text) ?? 0;
                                  final newVal = (n + 1).clamp(0, 999);
                                  _aController.text = newVal.toString();
                                  setState(() => widget.vm.a = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // C
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final n = int.tryParse(_cController.text) ?? 0;
                                  final newVal = (n - 1).clamp(0, 999);
                                  _cController.text = newVal.toString();
                                  setState(() => widget.vm.c = newVal);
                                },
                              ),
                              Expanded(
                                child: TextField(
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final n = int.tryParse(_cController.text) ?? 0;
                                  final newVal = (n + 1).clamp(0, 999);
                                  _cController.text = newVal.toString();
                                  setState(() => widget.vm.c = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // D
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final n = int.tryParse(_dController.text) ?? 0;
                                  final newVal = (n - 1).clamp(0, 999);
                                  _dController.text = newVal.toString();
                                  setState(() => widget.vm.d = newVal);
                                },
                              ),
                              Expanded(
                                child: TextField(
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final n = int.tryParse(_dController.text) ?? 0;
                                  final newVal = (n + 1).clamp(0, 999);
                                  _dController.text = newVal.toString();
                                  setState(() => widget.vm.d = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Misses
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final n = int.tryParse(_missesController.text) ?? 0;
                                  final newVal = (n - 1).clamp(0, 999);
                                  _missesController.text = newVal.toString();
                                  setState(() => widget.vm.misses = newVal);
                                },
                              ),
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
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final n = int.tryParse(_missesController.text) ?? 0;
                                  final newVal = (n + 1).clamp(0, 999);
                                  _missesController.text = newVal.toString();
                                  setState(() => widget.vm.misses = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // No Shoots
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final n = int.tryParse(_noShootsController.text) ?? 0;
                                  final newVal = (n - 1).clamp(0, 999);
                                  _noShootsController.text = newVal.toString();
                                  setState(() => widget.vm.noShoots = newVal);
                                },
                              ),
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
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final n = int.tryParse(_noShootsController.text) ?? 0;
                                  final newVal = (n + 1).clamp(0, 999);
                                  _noShootsController.text = newVal.toString();
                                  setState(() => widget.vm.noShoots = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Procedure Errors
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  final n = int.tryParse(_procErrorsController.text) ?? 0;
                                  final newVal = (n - 1).clamp(0, 999);
                                  _procErrorsController.text = newVal.toString();
                                  setState(() => widget.vm.procErrors = newVal);
                                },
                              ),
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
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  final n = int.tryParse(_procErrorsController.text) ?? 0;
                                  final newVal = (n + 1).clamp(0, 999);
                                  _procErrorsController.text = newVal.toString();
                                  setState(() => widget.vm.procErrors = newVal);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stage: ${r.stage}, Time: ${r.time.toStringAsFixed(2)}'),
                            Text('A: ${r.a}, C: ${r.c}, D: ${r.d}, Misses: ${r.misses}, No Shoots: ${r.noShoots}, Proc Err: ${r.procedureErrors}'),
                            Builder(
                              builder: (context) {
                                final shooter = repo.getShooter(r.shooter);
                                final scale = shooter?.scaleFactor ?? 1.0;
                                return Text('Hit Factor: ${r.hitFactor.toStringAsFixed(2)}, Adjusted: ${r.adjustedHitFactor(scale).toStringAsFixed(2)}');
                              },
                            ),
                          ],
                        ),
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
