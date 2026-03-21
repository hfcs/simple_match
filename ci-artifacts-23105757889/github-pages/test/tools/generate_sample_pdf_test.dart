// This file does not contain a leading code fence.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/models/stage_result.dart';
import 'package:simple_match/models/shooter.dart';
import 'package:simple_match/models/match_stage.dart';

class SimpleResult {
  final String name;
  final double totalPoints;
  SimpleResult(this.name, this.totalPoints);
}

void main() {
  testWidgets('generate sample overall result pdf', (WidgetTester tester) async {
    // Prepare simple test data
    final results = [SimpleResult('Alice', 123.45), SimpleResult('Bob', 98.76)];
    final stages = [MatchStage(stage: 1, scoringShoots: 10)];
    final shooters = [Shooter(name: 'Alice', scaleFactor: 1.0), Shooter(name: 'Bob', scaleFactor: 0.9)];
    final allResults = [
      StageResult(stage: 1, shooter: 'Alice', time: 30.0, a: 10, c: 0, d: 0),
      StageResult(stage: 1, shooter: 'Bob', time: 32.0, a: 9, c: 0, d: 0),
    ];

    // Build PDF inside runAsync to avoid test timeout issues for heavy IO
    await tester.runAsync(() async {
      final pdf = await buildOverallResultPdf(
        results: results,
        stages: stages,
        shooters: shooters,
        allResults: allResults,
        teamGame: null,
      );

      final bytes = await pdf.save();

      final out = File('tmp/sample_overall_results.pdf');
      await out.create(recursive: true);
      await out.writeAsBytes(bytes);
      // Print path for CI / logs
      print('SAMPLE_PDF: ${out.path}');
    });
  }, timeout: const Timeout(Duration(seconds: 30)));
}
