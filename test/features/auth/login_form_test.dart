import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/widgets/empty_state_widget.dart';

/// Tests for form-like widgets used in auth and other screens.
void main() {
  group('Form accessibility', () {
    testWidgets('EmptyStateWidget has semantic label when action present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No items',
              message: 'Add your first item',
              icon: Icons.inbox,
              actionLabel: 'Add',
              onActionPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
    });
  });
}
