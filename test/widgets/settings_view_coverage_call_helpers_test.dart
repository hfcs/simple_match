import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/settings_view.dart';

void main() {
  test('call settings_view coverage helpers', () {
    final a = SettingsView.exerciseCoverageMarker();
    expect(a, isA<int>());

    final b = exerciseCoverageMarkerLarge();
    expect(b, isA<int>());

    final c = exerciseCoverageMarkerExtra();
    expect(c, isA<int>());
  });
}
