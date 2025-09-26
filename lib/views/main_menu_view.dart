import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/match_repository.dart';

/// Main menu view with navigation buttons.
class MainMenuView extends StatelessWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini IPSC Match')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Match Setup'),
                onTap: () => Navigator.pushNamed(context, '/match-setup'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Shooter Setup'),
                onTap: () => Navigator.pushNamed(context, '/shooter-setup'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.input),
                title: const Text('Stage Input'),
                onTap: () => Navigator.pushNamed(context, '/stage-input'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Stage Result'),
                onTap: () => Navigator.pushNamed(context, '/stage-result'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('Overall Result'),
                onTap: () => Navigator.pushNamed(context, '/overall-result'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Data'),
                      content: const Text('Are you sure you want to clear all data? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (confirmed == true) {
                    final repo = context.read<MatchRepository>();
                    await repo.clearAllData();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All data cleared.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
