// Basic Flutter widget smoke test.
// Full TripsFactoryApp test requires ProviderScope, Supabase, Firebase init - run as integration test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('TripsFactory'),
        ),
      ),
    );
    expect(find.text('TripsFactory'), findsOneWidget);
  });
}
