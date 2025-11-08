// Temporarily ignore deprecated Radio API uses; refactor to RadioGroup in a follow-up
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/stage_input_viewmodel.dart';

class StageInputView extends StatefulWidget {
  const StageInputView({super.key});
  @override
  State<StageInputView> createState() => _StageInputViewState();
}

class _StageInputViewState extends State<StageInputView> {
  final _timeController = TextEditingController();
  final _aController = TextEditingController();
  final _cController = TextEditingController();
  final _dController = TextEditingController();
  final _missesController = TextEditingController();
  final _noShootsController = TextEditingController();
  final _procErrorsController = TextEditingController();
  final _roRemarkController = TextEditingController();

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
  _roRemarkController.dispose();
    super.dispose();
  }

  void _refreshFields(StageInputViewModel vm) {
    _timeController.text = vm.time.toString();
    _aController.text = vm.a.toString();
    _cController.text = vm.c.toString();
    _dController.text = vm.d.toString();
    _missesController.text = vm.misses.toString();
    _noShootsController.text = vm.noShoots.toString();
    _procErrorsController.text = vm.procErrors.toString();
    _roRemarkController.text = vm.roRemark;
  }

  void _clearEditing(StageInputViewModel vm) {
    setState(() {
      _editingKey = null;
      _refreshFields(vm);
    });
  }

  void _setA(StageInputViewModel vm, int value) {
    _aController.text = value.toString();
    setState(() => vm.a = value);
  }

  void _setC(StageInputViewModel vm, int value) {
    _cController.text = value.toString();
    setState(() => vm.c = value);
  }

  void _setD(StageInputViewModel vm, int value) {
    _dController.text = value.toString();
    setState(() => vm.d = value);
  }

  void _setMisses(StageInputViewModel vm, int value) {
    _missesController.text = value.toString();
    setState(() => vm.misses = value);
  }

  void _setNoShoots(StageInputViewModel vm, int value) {
    _noShootsController.text = value.toString();
    setState(() => vm.noShoots = value);
  }

  void _setProcErrors(StageInputViewModel vm, int value) {
    _procErrorsController.text = value.toString();
    setState(() => vm.procErrors = value);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StageInputViewModel>(context);
    final repo = vm.repository;
    final results = repo.results;
    final stages = repo.stages;
    final shooters = repo.shooters;
    final isValid = vm.isValid;
    final validationError = vm.validationError;

    // Use a LayoutBuilder to apply a responsive minimum height for the
    // input area. We cap the minHeight to the available max height so tests
    // and small viewports do not push interactive controls off-screen.
    //
    // Rationale: earlier a fixed large minHeight caused widget tests to
    // produce hit-test warnings (widgets appearing off-screen). The cap
    // ensures a reasonable minimum visual layout on large screens while
    // remaining test-friendly.
    return Scaffold(
      appBar: AppBar(title: const Text('Stage Input')),
      body: LayoutBuilder(builder: (context, constraints) {
    // Use a modest cap (800) for minHeight on very large screens so the
    // layout remains visually pleasing but doesn't force huge off-screen
    // scrolling in tests or small windows.
    final minHeight = constraints.maxHeight > 1000.0
      ? 800.0
      : constraints.maxHeight;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
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
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                              // Stage selector implemented with PopupMenuButton for
                              // more reliable overlay/menu behavior in tests.
                              Builder(builder: (context) {
                                return InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Stage',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: PopupMenuButton<int>(
                                    key: const Key('stageSelector'),
                                    onSelected: (v) {
                                      vm.selectStage(v);
                                      _refreshFields(vm);
                                    },
                                    itemBuilder: (_) => stages
                                        .map(
                                          (s) => PopupMenuItem<int>(
                                            value: s.stage,
                                            child: Text('Stage ${s.stage}'),
                                          ),
                                        )
                                        .toList(),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(vm.selectedStage == null
                                            ? 'Select Stage'
                                            : 'Stage ${vm.selectedStage}'),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              // Shooter selector (moved up to be just under stage selector)
                              Builder(builder: (context) {
                                return InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Shooter',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: PopupMenuButton<String>(
                                    key: const Key('shooterSelector'),
                                    onSelected: (v) {
                                      vm.selectShooter(v);
                                      _refreshFields(vm);
                                    },
                                    itemBuilder: (_) => shooters.map((s) {
                                          final hasDQ = repo.results.any((r) => r.shooter == s.name && r.status == 'DQ');
                                          return PopupMenuItem<String>(
                                            value: s.name,
                                            enabled: !hasDQ,
                                            child: Text(
                                              hasDQ ? "${s.name} (DQ'ed)" : s.name,
                                              style: hasDQ ? const TextStyle(color: Colors.grey) : null,
                                            ),
                                          );
                                        }).toList(),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(vm.selectedShooter ?? 'Select Shooter'),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              // ...existing code...
                              // Time
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      final t =
                                          double.tryParse(_timeController.text) ??
                                          0.0;
                                      final newVal = (t - 0.01).clamp(0.0, 999.99);
                                      _timeController.text = newVal.toStringAsFixed(2);
                                      setState(() => vm.time = newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (v) {
                                        final t = double.tryParse(v) ?? 0.0;
                                        setState(() => vm.time = t);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final t =
                                          double.tryParse(_timeController.text) ??
                                          0.0;
                                      final newVal = (t + 0.01).clamp(0.0, 999.99);
                                      _timeController.text = newVal.toStringAsFixed(2);
                                      setState(() => vm.time = newVal);
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
                                      _setA(vm, newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                      onChanged: (v) {
                                        final n = int.tryParse(v) ?? 0;
                                        _aController.value = TextEditingValue(
                                          text: v,
                                          selection: TextSelection.collapsed(
                                            offset: v.length,
                                          ),
                                        );
                                        setState(() => vm.a = n);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final n = int.tryParse(_aController.text) ?? 0;
                                      final newVal = (n + 1).clamp(0, 999);
                                      _setA(vm, newVal);
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
                                      _setC(vm, newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                      onChanged: (v) {
                                        final n = int.tryParse(v) ?? 0;
                                        _cController.value = TextEditingValue(
                                          text: v,
                                          selection: TextSelection.collapsed(
                                            offset: v.length,
                                          ),
                                        );
                                        setState(() => vm.c = n);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final n = int.tryParse(_cController.text) ?? 0;
                                      final newVal = (n + 1).clamp(0, 999);
                                      _setC(vm, newVal);
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
                                      _setD(vm, newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                      onChanged: (v) {
                                        final n = int.parse(v.isEmpty ? '0' : v);
                                        _dController.value = TextEditingValue(
                                          text: v,
                                          selection: TextSelection.collapsed(
                                            offset: v.length,
                                          ),
                                        );
                                        setState(() => vm.d = n);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final n = int.tryParse(_dController.text) ?? 0;
                                      final newVal = (n + 1).clamp(0, 999);
                                      _setD(vm, newVal);
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
                                      _setMisses(vm, newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                      onChanged: (v) {
                                        final n = int.tryParse(v) ?? 0;
                                        _missesController.value = TextEditingValue(
                                          text: v,
                                          selection: TextSelection.collapsed(
                                            offset: v.length,
                                          ),
                                        );
                                        setState(() => vm.misses = n);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final n = int.tryParse(_missesController.text) ?? 0;
                                      final newVal = (n + 1).clamp(0, 999);
                                      _setMisses(vm, newVal);
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
                                      _setNoShoots(vm, newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                      onChanged: (v) {
                                        final n = int.tryParse(v) ?? 0;
                                        _noShootsController.value = TextEditingValue(
                                          text: v,
                                          selection: TextSelection.collapsed(
                                            offset: v.length,
                                          ),
                                        );
                                        setState(() => vm.noShoots = n);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final n = int.tryParse(_noShootsController.text) ?? 0;
                                      final newVal = (n + 1).clamp(0, 999);
                                      _setNoShoots(vm, newVal);
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
                                      _setProcErrors(vm, newVal);
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
                                      enabled: vm.status == 'Completed',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                      onChanged: (v) {
                                        final n = int.tryParse(v) ?? 0;
                                        _procErrorsController.value = TextEditingValue(
                                          text: v,
                                          selection: TextSelection.collapsed(
                                            offset: v.length,
                                          ),
                                        );
                                        setState(() => vm.procErrors = n);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final n = int.tryParse(_procErrorsController.text) ?? 0;
                                      final newVal = (n + 1).clamp(0, 999);
                                      _setProcErrors(vm, newVal);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Status selector (Completed / DNF / DQ)
                              Row(
                                children: [
                                  const Text('Status:'),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('Completed'),
                                            value: 'Completed',
                                            groupValue: vm.status,
                                            onChanged: (v) {
                                              if (v != null) vm.setStatus(v);
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('DNF'),
                                            value: 'DNF',
                                            groupValue: vm.status,
                                            onChanged: (v) {
                                              if (v != null) vm.setStatus(v);
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('DQ'),
                                            value: 'DQ',
                                            groupValue: vm.status,
                                            onChanged: (v) {
                                              if (v != null) vm.setStatus(v);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // roRemark input
                              TextField(
                                key: const Key('roRemarkField'),
                                decoration: const InputDecoration(
                                  labelText: 'RO Remark',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _roRemarkController,
                                onChanged: (v) => vm.setRoRemark(v),
                              ),
                              const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                              // end of card content
                        ElevatedButton(
                          key: const Key('submitButton'),
                          onPressed: isValid
                              ? () async {
                                  await vm.submit();
                                  vm.reload();
                                  _clearEditing(vm);
                                  WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
                                }
                              : null,
                          child: Text(_editingKey == null ? 'Submit' : 'Update'),
                        ),
                        if (validationError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              validationError,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Hit Factor: ${vm.hitFactor.toStringAsFixed(2)}'),
                            const SizedBox(width: 16),
                            Text('Adjusted: ${vm.adjustedHitFactor.toStringAsFixed(2)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Results:', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                // Show stage and time only for completed results. For
                                // DNF/DQ we show status-only (and RO remark if present).
                                if (r.status == 'DNF' || r.status == 'DQ')
                                  const SizedBox.shrink()
                                else
                                  Text('Stage: ${r.stage}, Time: ${r.time.toStringAsFixed(2)}'),
                                // If the result was a DNF or DQ show only the status
                                // instead of the numeric breakdown. Always show the
                                // RO remark if present regardless of status.
                                if (r.status == 'DNF' || r.status == 'DQ') ...[
                                  Text('Status: ${r.status}'),
                                ] else ...[
                                  Text('A: ${r.a}, C: ${r.c}, D: ${r.d}, Misses: ${r.misses}, No Shoots: ${r.noShoots}, Proc Err: ${r.procedureErrors}'),
                                  Builder(builder: (context) {
                                    final shooter = repo.getShooter(r.shooter);
                                    final scale = shooter?.scaleFactor ?? 1.0;
                                    return Text('Hit Factor: ${r.hitFactor.toStringAsFixed(2)}, Adjusted: ${r.adjustedHitFactor(scale).toStringAsFixed(2)}');
                                  }),
                                ],
                                if (r.roRemark.isNotEmpty) Text('RO: ${r.roRemark}'),
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
                                      vm.selectStage(r.stage);
                                      vm.selectShooter(r.shooter);
                                      _editingKey = '${r.stage}-${r.shooter}';
                                      _refreshFields(vm);
                                    });
                                  },
                                ),
                                IconButton(
                                  key: Key('removeResult-${r.stage}-${r.shooter}'),
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    vm.selectStage(r.stage);
                                    vm.selectShooter(r.shooter);
                                    await vm.remove();
                                    setState(() {
                                      _editingKey = null;
                                      _refreshFields(vm);
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
                ], // end else ...[
              ], // end Column children
            ), // end Column
          ), // end Padding inside ConstrainedBox
        ); // end ConstrainedBox
      }), // end LayoutBuilder
    ); // end Scaffold
  } // end build
} // end class
