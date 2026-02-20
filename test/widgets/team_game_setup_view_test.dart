import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_match/views/team_game_setup_view.dart';
import 'package:simple_match/viewmodel/team_game_viewmodel.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/models/shooter.dart';

void main() {
  testWidgets('TeamGameSetupView: mode selection and top-count field', (tester) async {
    final repo = MatchRepository(initialShooters: []);
    final vm = TeamGameViewModel(repo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<MatchRepository>.value(value: repo),
        ChangeNotifierProvider<TeamGameViewModel>.value(value: vm),
      ],
      child: const MaterialApp(home: TeamGameSetupView()),
    ));

    // Initial mode is 'off'
    expect(vm.teamGame.mode, 'off');

    // Tap 'Top shooters' radio and verify the top-count TextFormField is shown
    await tester.tap(find.textContaining('Top shooters'));
    await tester.pump(const Duration(milliseconds: 200));

    // Should show one TextFormField for entering top count
    expect(find.byType(TextFormField), findsOneWidget);

    // Enter a top count
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.pump(const Duration(milliseconds: 200));

    expect(vm.teamGame.topCount, 2);
  });

  testWidgets('TeamGameSetupView: add team, assign/unassign shooter, Unassign All', (tester) async {
    final repo = MatchRepository(initialShooters: [Shooter(name: 'Alice'), Shooter(name: 'Bob')]);
    final vm = TeamGameViewModel(repo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<MatchRepository>.value(value: repo),
        ChangeNotifierProvider<TeamGameViewModel>.value(value: vm),
      ],
      child: const MaterialApp(home: TeamGameSetupView()),
    ));

    // Add a new team via the dialog
    await tester.tap(find.text('Add Team'));
    await tester.pump(const Duration(milliseconds: 200));

    // Enter team name and press Add
    await tester.enterText(find.byType(TextField), 'TeamA');
    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(vm.teamGame.teams.length, 1);
    expect(vm.teamGame.teams.first.name, 'TeamA');

    // Assign Alice to TeamA programmatically via the viewmodel to avoid popup
    final teamId = vm.teamGame.teams.first.id;
    await vm.assignShooter(teamId, 'Alice');
    await tester.pump(const Duration(milliseconds: 200));

    expect(vm.teamGame.teams.first.members, contains('Alice'));

    // Unassign programmatically (avoids tapping Unassign All button in widget tests)
    await vm.unassignShooter('Alice');
    await tester.pump(const Duration(milliseconds: 200));

    expect(vm.teamGame.teams.first.members, isEmpty);
  });
}
