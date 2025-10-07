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

	void _refreshFields(StageInputViewModel vm) {
		_timeController.text = vm.time.toString();
		_aController.text = vm.a.toString();
		_cController.text = vm.c.toString();
		_dController.text = vm.d.toString();
		_missesController.text = vm.misses.toString();
		_noShootsController.text = vm.noShoots.toString();
		_procErrorsController.text = vm.procErrors.toString();
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
														initialValue: stages.any((s) => s.stage == vm.selectedStage)
																? vm.selectedStage
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
																	vm.selectStage(v);
																	_refreshFields(vm);
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
														initialValue: shooters.any((s) => s.name == vm.selectedShooter)
																? vm.selectedShooter
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
																	vm.selectShooter(v);
																	_refreshFields(vm);
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: true),
																	onChanged: (v) {
																		final t = double.tryParse(v) ?? 0.0;
																		setState(() => vm.time = t);
																	},
																),
															),
															IconButton(
																icon: const Icon(Icons.add),
																onPressed: () {
																	final t = double.tryParse(_timeController.text) ?? 0.0;
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
																	onChanged: (v) {
																		final n = int.tryParse(v) ?? 0;
																		_aController.value = TextEditingValue(
																			text: v,
																			selection: TextSelection.collapsed(offset: v.length),
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
																	onChanged: (v) {
																		final n = int.tryParse(v) ?? 0;
																		_cController.value = TextEditingValue(
																			text: v,
																			selection: TextSelection.collapsed(offset: v.length),
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
																	onChanged: (v) {
																		final n = int.tryParse(v) ?? 0;
																		_dController.value = TextEditingValue(
																			text: v,
																			selection: TextSelection.collapsed(offset: v.length),
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
																	onChanged: (v) {
																		final n = int.tryParse(v) ?? 0;
																		_missesController.value = TextEditingValue(
																			text: v,
																			selection: TextSelection.collapsed(offset: v.length),
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
																	onChanged: (v) {
																		final n = int.tryParse(v) ?? 0;
																		_noShootsController.value = TextEditingValue(
																			text: v,
																			selection: TextSelection.collapsed(offset: v.length),
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
																	keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
																	onChanged: (v) {
																		final n = int.tryParse(v) ?? 0;
																		_procErrorsController.value = TextEditingValue(
																			text: v,
																			selection: TextSelection.collapsed(offset: v.length),
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
															child: Text(validationError, style: const TextStyle(color: Colors.red)),
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
						],
					],
				),
			),
		);
	}
}
