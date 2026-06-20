import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No items',
              message: 'Add your first item',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add your first item'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              message: 'No data',
              icon: Icons.cloud_off,
              actionLabel: 'Retry',
              onActionPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('hides action button when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              message: 'No data',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
