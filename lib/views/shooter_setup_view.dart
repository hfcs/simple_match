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
  final _handicapController = TextEditingController();
  String? _error;
  String? _editingName;

  @override
  void dispose() {
    _nameController.dispose();
    _handicapController.dispose();
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
            TextField(
              key: const Key('nameField'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              enabled: _editingName == null,
            ),
            TextField(
              key: const Key('handicapField'),
              controller: _handicapController,
              decoration: const InputDecoration(labelText: 'Handicap (0.00-1.00)'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              children: [
                if (_editingName == null)
                  ElevatedButton(
                    key: const Key('addShooterButton'),
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final handicap = double.tryParse(_handicapController.text);
                      final err = (handicap == null)
                          ? 'Invalid handicap.'
                          : widget.vm.addShooter(name, handicap);
                      setState(() => _error = err);
                      if (err == null) {
                        _nameController.clear();
                        _handicapController.clear();
                      }
                    },
                    child: const Text('Add Shooter'),
                  )
                else ...[
                  ElevatedButton(
                    key: const Key('confirmEditButton'),
                    onPressed: () {
                      final handicap = double.tryParse(_handicapController.text);
                      final err = (handicap == null)
                          ? 'Invalid handicap.'
                          : widget.vm.editShooter(_editingName!, handicap);
                      setState(() => _error = err);
                      if (err == null) {
                        setState(() => _editingName = null);
                        _nameController.clear();
                        _handicapController.clear();
                      }
                    },
                    child: const Text('Confirm Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _editingName = null);
                      _nameController.clear();
                      _handicapController.clear();
                      _error = null;
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Text('Shooters:'),
            Expanded(
              child: ListView(
                children: [
                  for (final s in shooters)
                    ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.handicapFactor.toString()),
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
                                _handicapController.text = s.handicapFactor.toString();
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
                                  _handicapController.clear();
                                }
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

// (Removed duplicate class definitions and stray brace)
