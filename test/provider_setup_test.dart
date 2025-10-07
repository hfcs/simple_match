import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_match/main.dart';
import 'package:simple_match/repository/match_repository.dart';
import 'package:simple_match/viewmodel/main_menu_viewmodel.dart';
import 'package:simple_match/viewmodel/match_setup_viewmodel.dart';
import 'package:simple_match/viewmodel/shooter_setup_viewmodel.dart';
import 'package:simple_match/viewmodel/stage_input_viewmodel.dart';
import 'package:simple_match/viewmodel/overall_result_viewmodel.dart';
import 'package:simple_match/views/main_menu_view.dart';

void main() {
  testWidgets('Provider tree is set up and provides all viewmodels', (
    tester,
  ) async {
    final repo = MatchRepository();
    await tester.pumpWidget(MiniIPSCMatchApp(repository: repo));
    // Find a widget below the MultiProvider (MainMenuView)
    final context = tester.element(find.byType(MainMenuView));
    expect(
      Provider.of<MatchRepository>(context, listen: false),
      isA<MatchRepository>(),
    );
    expect(
      Provider.of<MainMenuViewModel>(context, listen: false),
      isA<MainMenuViewModel>(),
    );
    expect(
      Provider.of<MatchSetupViewModel>(context, listen: false),
      isA<MatchSetupViewModel>(),
    );
    expect(
      Provider.of<ShooterSetupViewModel>(context, listen: false),
      isA<ShooterSetupViewModel>(),
    );
    expect(
      Provider.of<StageInputViewModel>(context, listen: false),
      isA<StageInputViewModel>(),
    );
    expect(
      Provider.of<OverallResultViewModel>(context, listen: false),
      isA<OverallResultViewModel>(),
    );
  });
}
