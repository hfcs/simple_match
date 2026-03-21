import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:simple_match/views/stage_result_view.dart';
import 'package:simple_match/viewmodel/stage_result_viewmodel.dart';
import 'package:simple_match/services/persistence_service.dart';

void main() {
  group('StageResultView uncovered UI/logic', () {
    testWidgets('shows empty state when no stages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StageResultView(
            viewModel: StageResultViewModel(
              persistenceService: PersistenceService(),
            ),
          ),
        ),
      );
      expect(find.text('No stages available.'), findsOneWidget);
    });
  });
}
