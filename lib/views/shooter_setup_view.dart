import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/shooter_setup_viewmodel.dart';

/// Shooter setup view skeleton.
class ShooterSetupView extends StatelessWidget {
  const ShooterSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShooterSetupViewModel>(
      builder: (context, vm, _) => _ShooterSetupViewBody(vm: vm),
    );
  }
}

class _ShooterSetupViewBody extends StatefulWidget {
  final ShooterSetupViewModel vm;
  const _ShooterSetupViewBody({required this.vm});

  @override
  State<_ShooterSetupViewBody> createState() => _ShooterSetupViewBodyState();
}

class _ShooterSetupViewBodyState extends State<_ShooterSetupViewBody> {
  final _nameController = TextEditingController();
  final _scaleController = TextEditingController();
  String? _error;
  String? _editingName;

  @override
  void dispose() {
    _nameController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shooters = widget.vm.repository.shooters;
    return Scaffold(
      appBar: AppBar(title: const Text('Shooter Setup')),
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
                      key: const Key('nameField'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _editingName == null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('scaleField'),
                      controller: _scaleController,
                      decoration: const InputDecoration(
                        labelText: 'Scale (0.10-2.00)',
                        prefixIcon: Icon(Icons.percent),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        if (_editingName == null)
                          ElevatedButton.icon(
                            key: const Key('addShooterButton'),
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final name = _nameController.text.trim();
                              final scale = double.tryParse(
                                _scaleController.text,
                              );
                              final err = (scale == null)
                                  ? 'Invalid scale.'
                                  : widget.vm.addShooter(name, scale);
                              setState(() => _error = err);
                              if (err == null) {
                                _nameController.clear();
                                _scaleController.clear();
                              }
                            },
                            label: const Text('Add Shooter'),
                          )
                        else ...[
                          ElevatedButton.icon(
                            key: const Key('confirmEditButton'),
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              final scale = double.tryParse(
                                _scaleController.text,
                              );
                              final err = (scale == null)
                                  ? 'Invalid scale.'
                                  : widget.vm.editShooter(_editingName!, scale);
                              setState(() => _error = err);
                              if (err == null) {
                                setState(() => _editingName = null);
                                _nameController.clear();
                                _scaleController.clear();
                              }
                            },
                            label: const Text('Confirm Edit'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _editingName = null);
                              _nameController.clear();
                              _scaleController.clear();
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
              'Shooters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: shooters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final s = shooters[idx];
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Row(
                        children: [
                          Text(s.name),
                          const SizedBox(width: 12),
                          Text(
                            s.scaleFactor.toStringAsFixed(2),
                            key: Key('scaleValue-${s.name}'),
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Scale: ${s.scaleFactor.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('editShooter-${s.name}'),
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                _editingName = s.name;
                                _nameController.text = s.name;
                                _scaleController.text = s.scaleFactor
                                    .toString();
                                _error = null;
                              });
                            },
                          ),
                          IconButton(
                            key: Key('removeShooter-${s.name}'),
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              widget.vm.removeShooter(s.name);
                              setState(() {
                                if (_editingName == s.name) {
                                  _editingName = null;
                                  _nameController.clear();
                                  _scaleController.clear();
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

// (Removed duplicate class definitions and stray brace)
