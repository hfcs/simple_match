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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/match-setup'),
              child: const Text('Match Setup'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/shooter-setup'),
              child: const Text('Shooter Setup'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/stage-input'),
              child: const Text('Stage Input'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/overall-result'),
              child: const Text('Overall Result'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                if (confirmed == true) {
                  final repo = context.read<MatchRepository>();
                  await repo.clearAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared.')),
                  );
                }
              },
              child: const Text('Clear All Data'),
            ),
          ],
        ),
      ),
    );
  }
}
