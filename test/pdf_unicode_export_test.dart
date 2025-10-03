import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_match/views/overall_result_view.dart';
import 'package:simple_match/models/shooter.dart';

class DummyResult {
  final String name;
  final double totalPoints;
  DummyResult(this.name, this.totalPoints);
}

class DummyStage {
  final int stage;
  DummyStage(this.stage);
}


// Must match the real Shooter interface for .name and .scaleFactor
// Use the real Shooter model for compatibility


// Must match the real StageResult interface for .stage, .shooter, .hitFactor, .adjustedHitFactor, etc.
class DummyStageResult {
  final int stage;
  final String shooter;
  final double hitFactor;
  final double time;
  final int a, c, d, misses, noShoots, procedureErrors;
  DummyStageResult({
    required this.stage,
    required this.shooter,
    required this.hitFactor,
    required this.time,
    required this.a,
    required this.c,
    required this.d,
    required this.misses,
    required this.noShoots,
    required this.procedureErrors,
  });
  double adjustedHitFactor(double scaleFactor) => hitFactor * scaleFactor;
}

// Removed unused and incomplete _containsUtf8 function
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('PDF export renders Traditional Chinese shooter names (pdftotext extraction)', () async {
    final chineseName = '張偉';
    final results = [DummyResult(chineseName, 123.45)];
    final stages = [DummyStage(1)];
    final shooters = [Shooter(name: chineseName, scaleFactor: 1.0)];
    final allResults = [
      DummyStageResult(
        stage: 1,
        shooter: chineseName,
        hitFactor: 5.5,
        time: 10.0,
        a: 10,
        c: 5,
        d: 2,
        misses: 0,
        noShoots: 0,
        procedureErrors: 0,
      ),
    ];

    final pdf = await buildOverallResultPdf(
      results: results,
      stages: stages,
      shooters: shooters,
      allResults: allResults,
    );
    final tempDir = Directory.systemTemp.createTempSync();
    final pdfPath = p.join(tempDir.path, 'test.pdf');
    final pdfBytes = await pdf.save();
    File(pdfPath).writeAsBytesSync(pdfBytes);

    // Use pdftotext to extract text
    final result = await Process.run('pdftotext', [pdfPath, '-']);
    expect(result.exitCode, 0, reason: 'pdftotext failed: ${result.stderr}');
    final extractedText = result.stdout as String;
    expect(extractedText, contains(chineseName), reason: 'PDF should contain the Traditional Chinese shooter name in extracted text');

    tempDir.deleteSync(recursive: true);
  });
}
