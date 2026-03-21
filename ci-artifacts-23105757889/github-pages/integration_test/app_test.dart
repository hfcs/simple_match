import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simple_match/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app startup integration test', (tester) async {
    // This will run the real main() and cover startup code on a device/emulator.
    app.main();
    await tester.pumpAndSettle();
    // Optionally, add more UI checks here (e.g., expect(find.text('Mini IPSC Match'), findsOneWidget));
  });
}
