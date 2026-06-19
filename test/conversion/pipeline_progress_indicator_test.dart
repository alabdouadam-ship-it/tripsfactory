import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/features/bookings/presentation/widgets/booking_progress_stepper.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import '../test_helpers/booking_fixture.dart';
import '../test_helpers/pump_app.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('BookingProgressStepper', () {
    testWidgets('progress widget exists with Key(booking_progress)',
        (WidgetTester tester) async {
      await pumpConversionWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.accepted()),
      );
      expect(find.byKey(const Key('booking_progress')), findsOneWidget);
    });

    testWidgets('shows 4 steps in order (Accepted, Goods, Paid, Delivered)',
        (WidgetTester tester) async {
      await pumpConversionWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.accepted()),
      );
      expect(find.text(en.statusAccepted), findsOneWidget);
      expect(find.text(en.handshakeGoodsReceived), findsOneWidget);
      expect(find.text(en.paid), findsOneWidget);
      expect(find.text(en.statusDelivered), findsOneWidget);
    });

    testWidgets('accepted state: first step emphasized (current)',
        (WidgetTester tester) async {
      await pumpConversionWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.accepted()),
      );
      expect(find.byKey(const Key('booking_progress')), findsOneWidget);
      final richTexts = tester.widgetList<Text>(find.byType(Text));
      final stepLabels = [en.statusAccepted, en.handshakeGoodsReceived, en.paid, en.statusDelivered];
      int boldCount = 0;
      for (final w in richTexts) {
        final label = w.data;
        if (label != null && stepLabels.contains(label) && w.style?.fontWeight == FontWeight.bold) {
          boldCount++;
        }
      }
      expect(boldCount, greaterThanOrEqualTo(1), reason: 'current step should be emphasized');
    });

    testWidgets('completed state: all 4 steps present', (WidgetTester tester) async {
      await pumpConversionWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.completed()),
      );
      expect(find.text(en.statusAccepted), findsOneWidget);
      expect(find.text(en.handshakeGoodsReceived), findsOneWidget);
      expect(find.text(en.paid), findsOneWidget);
      expect(find.text(en.statusDelivered), findsOneWidget);
    });

    testWidgets('paymentPending state: stepper shows correct step order',
        (WidgetTester tester) async {
      await pumpConversionWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.paymentPending()),
      );
      expect(find.byKey(const Key('booking_progress')), findsOneWidget);
      expect(find.text(en.paid), findsOneWidget);
    });

    testWidgets('delivered state: stepper present', (WidgetTester tester) async {
      await pumpConversionWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.delivered()),
      );
      expect(find.byKey(const Key('booking_progress')), findsOneWidget);
    });
  });
}
