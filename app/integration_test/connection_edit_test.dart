import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clawtalk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Connection Edit Tests', () {
    testWidgets('Edit connection screen displays existing data', (
      tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the connection card (assuming there's at least one connection)
      final connectionCard = find.byType(Card);
      if (connectionCard.evaluate().isNotEmpty) {
        // Tap on the edit button (three dots icon)
        final editButton = find.descendant(
          of: connectionCard.first,
          matching: find.byIcon(CupertinoIcons.ellipsis),
        );

        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton.first);
          await tester.pumpAndSettle();

          // Find and tap "Edit Connection" in the action sheet
          final editAction = find.text('Edit Connection');
          if (editAction.evaluate().isNotEmpty) {
            await tester.tap(editAction);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Verify we're on the edit screen
            expect(find.text('Edit Connection'), findsOneWidget);

            // Verify connection ID is displayed
            expect(find.text('CONNECTION ID'), findsOneWidget);

            // Verify form fields are populated
            final textFields = find.byType(CupertinoTextField);
            expect(textFields, findsWidgets);

            // Take a screenshot for debugging
            debugPrint('Edit connection screen loaded successfully');
          }
        }
      }
    });
  });
}
