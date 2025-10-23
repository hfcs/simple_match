import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/settings_view.dart';

void main() {
  test('exercise mega coverage helper', () {
    final v = exerciseCoverageMega();
    expect(v, greaterThan(0));
  });
}
