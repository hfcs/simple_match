import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/overall_result_viewmodel.dart';

class OverallResultView extends StatelessWidget {
  const OverallResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OverallResultViewModel>(
      builder: (context, vm, _) {
        final results = vm.getOverallResults();
        return Scaffold(
          appBar: AppBar(title: const Text('Overall Result')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Shooter Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('No results yet.'))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = results[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(r.name),
                              trailing: Text(r.totalPoints.toStringAsFixed(2)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
