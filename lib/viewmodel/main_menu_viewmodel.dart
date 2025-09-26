import 'package:flutter/material.dart';
import '../repository/match_repository.dart';

/// ViewModel for main menu actions.
class MainMenuViewModel {
  final MatchRepository repository;
  MainMenuViewModel(this.repository);

  /// Navigates to a named route using the provided context.
  void navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  /// Clears all match data via the repository.
  Future<void> clearAllData() async {
    await repository.clearAllData();
  }
}
