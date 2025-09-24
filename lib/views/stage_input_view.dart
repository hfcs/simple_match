
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
    final stages = repo.stages;
    final shooters = repo.shooters;
    final results = repo.results;
    final selectedStage = widget.vm.selectedStage;
    final selectedShooter = widget.vm.selectedShooter;
    final isValid = widget.vm.isValid;
    final validationError = widget.vm.validationError;

    return Scaffold(
      appBar: AppBar(title: const Text('Stage Input')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('stageSelector'),
                    decoration: const InputDecoration(labelText: 'Stage'),
                    value: selectedStage,
                    items: stages
                        .map((s) => DropdownMenuItem(
                              value: s.stage,
                              child: Text(s.stage.toString()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        widget.vm.selectStage(v!);
                        _refreshFields();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('shooterSelector'),
                    decoration: const InputDecoration(labelText: 'Shooter'),
                    value: selectedShooter,
                    items: shooters
                        .map((s) => DropdownMenuItem(
                              value: s.name,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        widget.vm.selectShooter(v!);
                        _refreshFields();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('timeField'),
                    controller: _timeController,
                    decoration: const InputDecoration(labelText: 'Time (sec)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final t = double.tryParse(v) ?? 0.0;
                      setState(() => widget.vm.time = t);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('aField'),
                    controller: _aController,
                    decoration: const InputDecoration(labelText: 'A'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => widget.vm.a = n);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('cField'),
                    controller: _cController,
                    decoration: const InputDecoration(labelText: 'C'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => widget.vm.c = n);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('dField'),
                    controller: _dController,
                    decoration: const InputDecoration(labelText: 'D'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => widget.vm.d = n);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('missesField'),
                    controller: _missesController,
                    decoration: const InputDecoration(labelText: 'Misses'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => widget.vm.misses = n);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('noShootsField'),
                    controller: _noShootsController,
                    decoration: const InputDecoration(labelText: 'No Shoots'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => widget.vm.noShoots = n);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('procErrorsField'),
                    controller: _procErrorsController,
                    decoration: const InputDecoration(labelText: 'Procedure Errors'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => widget.vm.procErrors = n);
                    },
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
            const SizedBox(height: 24),
            const Text('Results:'),
            Expanded(
              child: ListView(
                children: [
                  for (final r in results)
                    ListTile(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
