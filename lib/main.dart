

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repository/match_repository.dart';
import 'viewmodel/main_menu_viewmodel.dart';
import 'viewmodel/match_setup_viewmodel.dart';
import 'viewmodel/shooter_setup_viewmodel.dart';
import 'viewmodel/stage_input_viewmodel.dart';
import 'viewmodel/overall_result_viewmodel.dart';
import 'views/main_menu_view.dart';
import 'views/match_setup_view.dart';
import 'views/shooter_setup_view.dart';
import 'views/stage_input_view.dart';
import 'views/overall_result_view.dart';

void main() {
  runApp(const MiniIPSCMatchApp());
}

class MiniIPSCMatchApp extends StatelessWidget {
  const MiniIPSCMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MatchRepository>(create: (_) => MatchRepository()),
        ProxyProvider<MatchRepository, MainMenuViewModel>(
          update: (_, repo, __) => MainMenuViewModel(repo),
        ),
        ProxyProvider<MatchRepository, MatchSetupViewModel>(
          update: (_, repo, __) => MatchSetupViewModel(repo),
        ),
        ProxyProvider<MatchRepository, ShooterSetupViewModel>(
          update: (_, repo, __) => ShooterSetupViewModel(repo),
        ),
        ProxyProvider<MatchRepository, StageInputViewModel>(
          update: (_, repo, __) => StageInputViewModel(repo),
        ),
        ProxyProvider<MatchRepository, OverallResultViewModel>(
          update: (_, repo, __) => OverallResultViewModel(repo),
        ),
      ],
      child: MaterialApp(
        title: 'Mini IPSC Match',
        initialRoute: '/', 
        routes: {
          '/': (context) => MainMenuView(),
          '/match-setup': (context) => const MatchSetupView(),
          '/shooter-setup': (context) => const ShooterSetupView(),
          '/stage-input': (context) => const StageInputView(),
          '/overall-result': (context) => const OverallResultView(),
        },
      ),
    );
  }
}
