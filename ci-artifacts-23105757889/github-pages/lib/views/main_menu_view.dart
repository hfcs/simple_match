import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/match_repository.dart';

/// Main menu view with navigation buttons.
class MainMenuView extends StatelessWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<MatchRepository>(context);

    final hasStages = repo.stages.isNotEmpty;
    final hasShooters = repo.shooters.isNotEmpty;
    final hasResults = repo.results.isNotEmpty;

    final canStageInput = hasStages && hasShooters;
    final canStageResult = hasResults;
    final canOverall = hasResults;
    final canClear = hasStages || hasShooters || hasResults;

    Widget menuCard({required Icon leading, required String title, String? subtitle, bool enabled = true, VoidCallback? onTap, Color? color}) {
      return Card(
        color: color,
        elevation: 2,
        child: ListTile(
          leading: leading,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
          enabled: enabled,
          onTap: enabled ? onTap : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mini IPSC Match')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          children: [
            menuCard(
              leading: const Icon(Icons.settings),
              title: 'Match Setup',
              onTap: () => Navigator.pushNamed(context, '/match-setup'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.build),
              title: 'Settings',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.person),
              title: 'Shooter Setup',
              onTap: () => Navigator.pushNamed(context, '/shooter-setup'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.group),
              title: 'Team Game Setup',
              subtitle: repo.shooters.isNotEmpty ? null : 'Add shooters first',
              enabled: repo.shooters.isNotEmpty,
              onTap: () => Navigator.pushNamed(context, '/team-game-setup'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.tune),
              title: 'Adjust Scaling',
              subtitle: repo.shooters.isNotEmpty ? null : 'Add shooters first',
              enabled: repo.shooters.isNotEmpty,
              onTap: () => Navigator.pushNamed(context, '/adjust-scaling'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.input),
              title: 'Stage Input',
              subtitle: canStageInput ? null : 'Add at least one stage and one shooter',
              enabled: canStageInput,
              onTap: () => Navigator.pushNamed(context, '/stage-input'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.bar_chart),
              title: 'Stage Result',
              subtitle: canStageResult ? null : 'No stage results yet — enter stage scores first',
              enabled: canStageResult,
              onTap: () => Navigator.pushNamed(context, '/stage-result'),
            ),
            const SizedBox(height: 16),
            menuCard(
              leading: const Icon(Icons.leaderboard),
              title: 'Overall Result',
              subtitle: canOverall ? null : 'No scoring data to compute overall results',
              enabled: canOverall,
              onTap: () => Navigator.pushNamed(context, '/overall-result'),
            ),
            const SizedBox(height: 16),
            canClear
                ? Card(
                    color: Colors.red[50],
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(
                        'Clear All Data',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear All Data'),
                            content: const Text(
                              'Are you sure you want to clear all data? This cannot be undone.',
                            ),
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
                  )
                : Card(
                    color: Colors.grey[200],
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.grey),
                      title: const Text('Clear All Data', style: TextStyle(color: Colors.grey)),
                      subtitle: const Text('Nothing to clear', style: TextStyle(color: Colors.grey)),
                      enabled: false,
                    ),
                  ),
            const SizedBox(height: 8),
            Center(
              child: SelectableText(
                'https://github.com/hfcs/simple_match',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
