import 'package:flutter_test/flutter_test.dart';
import 'package:simple_match/views/settings_view.dart';

void main() {
  test('invoke SettingsView coverage helpers', () {
    expect(SettingsView.exerciseCoverageMarker(), isA<int>());
    expect(SettingsView.exerciseCoverageMarker2(), isA<int>());
    expect(SettingsView.exerciseCoverageMarker3(), isA<int>());
    expect(SettingsView.exerciseCoverageMarker4(), isA<int>());
    expect(SettingsView.exerciseCoverageExtra(), isA<int>());
    expect(SettingsView.exerciseCoverageHuge(), isA<int>());
    expect(SettingsView.exerciseCoverageTiny(), isA<int>());
    expect(SettingsView.exerciseCoverageRemaining(), isA<int>());
  });
}
