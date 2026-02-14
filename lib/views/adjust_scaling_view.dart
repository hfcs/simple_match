import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/match_repository.dart';
import '../models/shooter.dart';

/// Adjust Scaling view: allows entering classification scores (0-100%)
/// for each shooter and aligning scale factors so the lowest CS becomes 1.
class AdjustScalingView extends StatefulWidget {
  const AdjustScalingView({super.key});

  @override
  State<AdjustScalingView> createState() => _AdjustScalingViewState();
}

class _AdjustScalingViewState extends State<AdjustScalingView> {
  final Map<String, TextEditingController> _controllers = {};
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allValid {
    if (_controllers.isEmpty) return false;
    for (final c in _controllers.values) {
      final text = c.text.trim();
      if (text.isEmpty) return false;
      final v = double.tryParse(text);
      if (v == null) return false;
      if (v <= 0 || v > 100) return false;
    }
    return true;
  }

  void _initControllers(MatchRepository repo) {
    for (final s in repo.shooters) {
      if (!_controllers.containsKey(s.name)) {
        _controllers[s.name] = TextEditingController(
          text: s.classificationScore.toStringAsFixed(1),
        );
      }
    }
    // Remove controllers for shooters that no longer exist
    final toRemove = _controllers.keys.where((k) => repo.getShooter(k) == null).toList();
    for (final k in toRemove) {
      _controllers.remove(k)?.dispose();
    }
  }

  Future<void> _alignScaling(MatchRepository repo) async {
    final parsed = <String, double>{};
    for (final entry in _controllers.entries) {
      final v = double.tryParse(entry.value.text.trim()) ?? 0.0;
      parsed[entry.key] = v;
    }

    final values = parsed.values.where((v) => v > 0).toList();
    if (values.isEmpty) return;
    final minCS = values.reduce((a, b) => a < b ? a : b);

    // Update each shooter: newScale = minCS / shooterCS
    for (final s in repo.shooters) {
      final cs = parsed[s.name] ?? s.classificationScore;
      final rawNewScale = cs <= 0 ? s.scaleFactor : (minCS / cs);
      // Clamp to allowed range [0.1, 20.0]
      final newScale = (rawNewScale as double).clamp(0.1, 20.0);
      final updated = Shooter(name: s.name, scaleFactor: newScale, classificationScore: cs);
      await repo.updateShooter(updated);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scaling factors updated from classification scores')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<MatchRepository>(context);
    _initControllers(repo);

    return Scaffold(
      appBar: AppBar(title: const Text('Adjust Scaling')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: repo.shooters.length,
                itemBuilder: (context, idx) {
                  final s = repo.shooters[idx];
                  final controller = _controllers[s.name]!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(s.name)),
                          Expanded(
                            flex: 2,
                            child: Text('Scale: ${s.scaleFactor.toStringAsFixed(3)}'),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                              decoration: const InputDecoration(
                                labelText: 'Classification %',
                                hintText: '0 - 100',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: _allValid ? () => _alignScaling(repo) : null,
                child: const Text('Align scaling to CS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
