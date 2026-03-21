import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/main.dart' as app;
import 'package:simple_match/repository/match_repository.dart';

void main() {
  testWidgets('dump app tree', (tester) async {
    await tester.pumpWidget(app.MiniIPSCMatchApp(repository: MatchRepository()));
    await tester.pump(const Duration(milliseconds: 200));
    debugDumpApp();
  });
}
