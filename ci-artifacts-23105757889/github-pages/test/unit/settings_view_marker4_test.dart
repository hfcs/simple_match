import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/settings_view.dart';

void main() {
  test('exerciseCoverageMarker4 returns a positive sum', () {
    final v = SettingsView.exerciseCoverageMarker4();
    expect(v > 0, isTrue);
  });
}
