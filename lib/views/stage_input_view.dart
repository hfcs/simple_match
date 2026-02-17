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
  // Raw-digit buffer for interactive plain-digit input (digits only,
  // without explicit decimal). We also track whether the value is
  // negative to preserve a leading '-' during editing.
  String _timeRawDigits = '';
  bool _timeNegative = false;
  bool _timeExplicitDecimal = false;
  bool _suppressTimeOnChange = false;
  String _lastFormattedDigits = '';
  String _lastControllerText = '';
  final _noShootsController = TextEditingController();
  final _procErrorsController = TextEditingController();
  final _roRemarkController = TextEditingController();
  final _timeFocusNode = FocusNode();
  

  // Fraction of vertical space allocated to the input area (0.0 - 1.0).
  // Default sets the lower (results) pane to 1/3 of the screen: inputFraction = 2/3.
  double _inputFraction = 2.0 / 3.0;

  @override
  void initState() {
    super.initState();
    _timeFocusNode.addListener(() {
      if (!_timeFocusNode.hasFocus) {
        // On blur, if user didn't type an explicit decimal, show a two-decimal
        // formatted value so the '.' becomes visible.
        final text = _timeController.text.trim();
        if (text.isNotEmpty && !text.contains('.')) {
          final t = _parseTimeInputValue(text);
          final display = t.toStringAsFixed(2);
          _timeController.value = TextEditingValue(
            text: display,
            selection: TextSelection.collapsed(offset: display.length),
          );
          _lastControllerText = display;
          // Update viewmodel
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => Provider.of<StageInputViewModel>(context, listen: false).time = t));
        }
      }
    });
  }

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
    _timeFocusNode.dispose();
    super.dispose();
  }

  void _setA(StageInputViewModel vm, int value) {
    _aController.text = value.toString();
    setState(() => vm.a = value);
  }

  void _setC(StageInputViewModel vm, int value) {
    _cController.text = value.toString();
    setState(() => vm.c = value);
  }

  double _parseTimeInputValue(String text) {
    final s = text.trim();
    if (s.isEmpty || s == '-') return 0.0;
    if (s.contains('.')) {
      return double.tryParse(s) ?? 0.0;
    }
    final digits = RegExp(r"\d").allMatches(s).map((m) => m.group(0)).join();
    if (digits.isEmpty) return 0.0;
    final intVal = int.tryParse(digits) ?? 0;
    return (digits.length <= 2) ? intVal.toDouble() : intVal / 100.0;
  }

  void _refreshFields(StageInputViewModel vm) {
    // Populate controllers from viewmodel
    _aController.text = vm.a.toString();
    _cController.text = vm.c.toString();
    _dController.text = vm.d.toString();
    _missesController.text = vm.misses.toString();
    _noShootsController.text = vm.noShoots.toString();
    _procErrorsController.text = vm.procErrors.toString();
    _roRemarkController.text = vm.roRemark;
    if (vm.time == 0.0) {
      _timeController.text = '';
      _lastControllerText = '';
      _lastFormattedDigits = '';
    } else {
      final display = vm.time.toStringAsFixed(2);
      _timeController.text = display;
      _lastControllerText = display;
      _lastFormattedDigits = display.replaceAll('.', '');
    }
  }

  void _clearEditing(StageInputViewModel vm) {
    _editingKey = null;
    _refreshFields(vm);
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
    final inputFlex = ((_inputFraction * 100).round()).clamp(30, 85).toInt();
    final resultsFlex = (100 - inputFlex).clamp(15, 70).toInt();

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
                    flex: inputFlex,
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
                                      final t = _parseTimeInputValue(_timeController.text);
                                      final newVal = (t - 0.01).clamp(0.0, 999.99);
                                      _suppressTimeOnChange = true;
                                      final display = newVal.toStringAsFixed(2);
                                      _timeController.text = display;
                                      _lastControllerText = display;
                                      _lastFormattedDigits = display.replaceAll('.', '');
                                      Future.microtask(() => _suppressTimeOnChange = false);
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
                                      focusNode: _timeFocusNode,
                                      onChanged: (v) {
                                        if (_suppressTimeOnChange) return;
                                        final s = v.trim();
                                        // Empty or just '-' -> reset buffer
                                        if (s.isEmpty || s == '-') {
                                          _timeRawDigits = '';
                                          _timeNegative = s.startsWith('-');
                                          _timeExplicitDecimal = false;
                                          final t = _parseTimeInputValue(v);
                                          setState(() => vm.time = t);
                                          return;
                                        }

                                        // Compute digits-only snapshot of the new input.
                                        final digitsInS = RegExp(r"\d").allMatches(s).map((m) => m.group(0)).join();

                                        // If the user removed the decimal point itself (previous
                                        // controller text had a '.' but the new input does not),
                                        // allow explicit decimal editing so backspace can continue
                                        // removing characters. Without this we immediately
                                        // re-format into a two-decimal display which prevents
                                        // the user from deleting the non-decimal part.
                                        if (!s.contains('.') && _lastControllerText.contains('.') && digitsInS.length <= _lastFormattedDigits.length) {
                                          _timeRawDigits = digitsInS;
                                          _timeExplicitDecimal = true;
                                          _timeNegative = s.startsWith('-');
                                          _suppressTimeOnChange = true;
                                          _timeController.value = TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
                                          _lastControllerText = s;
                                          Future.microtask(() => _suppressTimeOnChange = false);
                                          final parsed = double.tryParse(s) ?? (_timeRawDigits.isEmpty ? 0.0 : ((_timeRawDigits.length <= 2) ? (int.tryParse(_timeRawDigits) ?? 0).toDouble() : (int.tryParse(_timeRawDigits) ?? 0) / 100.0));
                                          setState(() => vm.time = parsed);
                                          return;
                                        }

                                        // If input contains a decimal, either treat as explicit
                                        // decimal editing or detect an append to our formatted
                                        // display (user typed while caret at end).
                                        if (s.contains('.')) {
                                          // If the user typed a single digit appended to our
                                          // last formatted display, interpret that as an
                                          // append to the raw-digit buffer. Example:
                                          // last display "9.00" -> lastFormattedDigits="900";
                                          // user types '3' -> digitsInS="9003" -> appended '3'.
                                          if (_lastFormattedDigits.isNotEmpty && digitsInS.startsWith(_lastFormattedDigits) && digitsInS.length == _lastFormattedDigits.length + 1 && !_timeExplicitDecimal) {
                                            final appended = digitsInS.substring(_lastFormattedDigits.length);
                                            _timeRawDigits = _timeRawDigits + appended;
                                            final intVal = _timeRawDigits.isEmpty ? 0 : int.tryParse(_timeRawDigits) ?? 0;
                                            final value = (_timeRawDigits.length <= 2) ? intVal.toDouble() : intVal / 100.0;
                                            final display = (_timeNegative ? '-' : '') + value.toStringAsFixed(2);
                                            _suppressTimeOnChange = true;
                                            _timeController.value = TextEditingValue(
                                              text: display,
                                              selection: TextSelection.collapsed(offset: display.length),
                                            );
                                            _lastControllerText = display;
                                            _lastFormattedDigits = display.replaceAll('.', '');
                                            Future.microtask(() => _suppressTimeOnChange = false);
                                            setState(() => vm.time = _timeNegative ? -value : value);
                                            return;
                                          }
                                          // Otherwise treat as explicit decimal entry
                                          _timeRawDigits = '';
                                          _timeExplicitDecimal = true;
                                          _timeNegative = s.startsWith('-');
                                          _lastFormattedDigits = digitsInS;
                                          final t = double.tryParse(s) ?? 0.0;
                                          setState(() => vm.time = t);
                                          return;
                                        }

                                        // Plain-digit mode: gather digits and update raw
                                        // buffer. Treat 1-2 digits as whole seconds, 3+
                                        // digits as having two implied decimals.
                                        final digits = RegExp(r"\d").allMatches(s).map((m) => m.group(0)).join();
                                        _timeRawDigits = digits;
                                        _timeNegative = s.startsWith('-');
                                        _timeExplicitDecimal = false;

                                        final intVal = _timeRawDigits.isEmpty ? 0 : int.tryParse(_timeRawDigits) ?? 0;
                                        final value = (_timeRawDigits.length <= 2) ? intVal.toDouble() : intVal / 100.0;

                                        // Display formatted two-decimal value but preserve
                                        // sign for negative inputs. Place caret at end.
                                        final display = (_timeNegative ? '-' : '') + value.toStringAsFixed(2);
                                        _suppressTimeOnChange = true;
                                        _timeController.value = TextEditingValue(
                                          text: display,
                                          selection: TextSelection.collapsed(offset: display.length),
                                        );
                                        // Keep a digits-only snapshot of the last formatted
                                        // text so we can detect single-digit appends.
                                        _lastFormattedDigits = display.replaceAll('.', '');
                                        // Release suppression asynchronously so the next
                                        // user keystroke is handled normally.
                                        Future.microtask(() => _suppressTimeOnChange = false);
                                        setState(() => vm.time = _timeNegative ? -value : value);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final t = _parseTimeInputValue(_timeController.text);
                                      final newVal = (t + 0.01).clamp(0.0, 999.99);
                                      _suppressTimeOnChange = true;
                                      final display = newVal.toStringAsFixed(2);
                                      _timeController.text = display;
                                      _lastControllerText = display;
                                      _lastFormattedDigits = display.replaceAll('.', '');
                                      Future.microtask(() => _suppressTimeOnChange = false);
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
                  // Small draggable handle to adjust input/results split (non-invasive for now)
                  Semantics(
                    label: 'Resize input area',
                    hint: 'Drag up or down to adjust input and results panes',
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (details) {
                        final total = MediaQuery.of(context).size.height;
                        setState(() {
                          _inputFraction += details.delta.dy / total;
                          _inputFraction = _inputFraction.clamp(0.30, 0.85);
                        });
                      },
                      onVerticalDragEnd: (_) async {
                        // Persisting this UI setting was removed: it's a client UI
                        // preference and not part of the shared data model.
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Results:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: resultsFlex,
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
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Remove Result'),
                                        content: Text('Remove result for ${r.shooter} on stage ${r.stage}?'),
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
                                      vm.selectStage(r.stage);
                                      vm.selectShooter(r.shooter);
                                      await vm.remove();
                                      setState(() {
                                        _editingKey = null;
                                        _refreshFields(vm);
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
                ], // end else ...[
              ], // end Column children
            ), // end Column
          ), // end Padding inside ConstrainedBox
        ); // end ConstrainedBox
      }), // end LayoutBuilder
    ); // end Scaffold
  } // end build
} // end class
