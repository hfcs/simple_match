import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/match_stage.dart';
import '../repository/match_repository.dart';

/// ViewModel for match setup page.
class MatchSetupViewModel {
  final MatchRepository repository;
  MatchSetupViewModel(this.repository);

  /// Adds a stage. Returns null on success, or error string on failure.
  String? addStage(int stage, int scoringShoots, {bool allowMoreThan32 = false}) {
    if (stage < 1 || stage > 30) return 'Stage must be between 1 and 30.';
    if (scoringShoots < 1 || (scoringShoots > 32 && !allowMoreThan32)) {
      return 'Scoring shoots must be between 1 and 32.';
    }
    if (repository.stages.any((s) => s.stage == stage)) {
      return 'Stage already exists.';
    }
    try {
      // Update repository state immediately; persist asynchronously.
      repository.addStage(MatchStage(stage: stage, scoringShoots: scoringShoots)).catchError((e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('DBG: MatchSetupViewModel.addStage background save failed: $e');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DBG: MatchSetupViewModel.addStage caught error: $e');
      }
      return 'Failed to add stage: $e';
    }
    return null;
  }

  /// Removes a stage by stage number.
  Future<void> removeStage(int stage) async {
    await repository.removeStage(stage);
  }

  /// Edits a stage's scoring shoots. Returns null on success, or error string on failure.
  String? editStage(int stage, int scoringShoots, {bool allowMoreThan32 = false}) {
    if (scoringShoots < 1 || (scoringShoots > 32 && !allowMoreThan32)) {
      return 'Scoring shoots must be between 1 and 32.';
    }
    final orig = repository.getStage(stage);
    if (orig == null) return 'Stage not found.';
    try {
      repository.updateStage(
        MatchStage(stage: stage, scoringShoots: scoringShoots, createdAt: orig.createdAt, updatedAt: orig.updatedAt),
      ).catchError((e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('DBG: MatchSetupViewModel.editStage background save failed: $e');
        }
      });
    } catch (e) {
      return 'Failed to update stage: $e';
    }
    return null;
  }
}
