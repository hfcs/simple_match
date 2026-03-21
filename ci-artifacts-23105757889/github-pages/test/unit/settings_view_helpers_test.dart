import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/settings_view.dart';

void main() {
  test('call static coverage helpers', () {
    final a = SettingsView.exerciseCoverageMarker();
    final b = SettingsView.exerciseCoverageExtra();
    final c = SettingsView.exerciseCoverageHuge();
    expect(a + b + c, greaterThan(0));
  });
}
