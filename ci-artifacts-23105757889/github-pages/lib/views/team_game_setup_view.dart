import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/team_game_viewmodel.dart';
import '../repository/match_repository.dart';
import '../models/team_game.dart';
import '../widgets/radio_group.dart';

class TeamGameSetupView extends StatefulWidget {
  const TeamGameSetupView({super.key});

  @override
  State<TeamGameSetupView> createState() => _TeamGameSetupViewState();
}

class _TeamGameSetupViewState extends State<TeamGameSetupView> {
  late TeamGameViewModel vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    vm = Provider.of<TeamGameViewModel>(context, listen: false);
    // Defer reload to after the first frame to avoid calling
    // notifyListeners() during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) vm.reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamGameViewModel>(builder: (context, vm, _) {
      final tg = vm.teamGame;
        return Scaffold(
          appBar: AppBar(title: const Text('Team Game Setup')),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Team scoring mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                AppRadioGroup<String>(
                  groupValue: tg.mode,
                  onChanged: (v) => vm.setMode(v ?? 'off'),
                  options: [
                    AppRadioOption(value: 'off', title: const Text('Team score deactivated')),
                    AppRadioOption(value: 'average', title: const Text('Overall average — Team score is average of all members')),
                    AppRadioOption(
                      value: 'top',
                      title: Row(children: [
                        const Expanded(child: Text('Top shooters — only top N shooters count')),
                        if (tg.mode == 'top')
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: tg.topCount.toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (s) {
                                final n = int.tryParse(s) ?? 0;
                                vm.setTopCount(n);
                              },
                            ),
                          ),
                      ]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Team'),
                      onPressed: () async {
                        final nameCtl = TextEditingController();
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('New Team'),
                            content: TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Team name')),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add'))],
                          ),
                        );
                        if (ok == true) await vm.addTeam(nameCtl.text.trim().isEmpty ? 'Team' : nameCtl.text.trim());
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Unassign All'),
                      onPressed: () async {
                        for (final s in vm.teamGame.teams.expand((t) => t.members).toList()) {
                          await vm.unassignShooter(s);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView(
                          children: vm.teamGame.teams.map((team) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: team.name,
                                        decoration: const InputDecoration(labelText: 'Team name'),
                                        onFieldSubmitted: (v) => vm.renameTeam(team.id, v),
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.delete), onPressed: () => vm.removeTeam(team.id)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text('Members: ${team.members.isEmpty ? 'none' : team.members.join(', ')}'),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 240,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('All Shooters', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView(
                                  children: Provider.of<MatchRepository>(context, listen: false).shooters.map((sh) {
                                    final assignedTeam = vm.teamGame.teams.firstWhere((t) => t.members.contains(sh.name), orElse: () => Team(id: '', name: ''));
                                    return ListTile(
                                      title: Text(sh.name),
                                      subtitle: assignedTeam.id.isEmpty ? const Text('Unassigned') : Text('Assigned to ${assignedTeam.name}'),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (teamId) async {
                                          if (teamId == '__unassign__') {
                                            await vm.unassignShooter(sh.name);
                                          } else {
                                            await vm.assignShooter(teamId, sh.name);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: '__unassign__', child: Text('Unassign')),
                                          ...vm.teamGame.teams.map((t) => PopupMenuItem(value: t.id, child: Text('Assign to ${t.name}'))),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
  }
}
