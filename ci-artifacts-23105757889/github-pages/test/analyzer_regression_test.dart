import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('static analyzer reports no issues', () async {
    // Run the same analyzer command CI uses. Fail the test if analyzer exits non-zero.
    final result = await Process.run('flutter', ['analyze']);
    // Forward output to test logs for easier debugging
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    expect(result.exitCode, 0, reason: 'Static analysis failed with exit code ${result.exitCode}');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
