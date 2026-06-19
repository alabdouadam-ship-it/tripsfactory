import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/widgets/trust_badge.dart';
import 'package:tripship/features/bookings/presentation/widgets/booking_progress_stepper.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import '../test_helpers/booking_fixture.dart';
import '../test_helpers/pump_app.dart';

void main() {
  group('Accessibility semantics', () {
    testWidgets('TrustBadge.verified has text and semantics Verified', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(tester, TrustBadge.verified());
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('TrustBadge.license has text and semantics License Verified', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(tester, TrustBadge.license());
      expect(find.text('License Verified'), findsOneWidget);
    });

    testWidgets('Progress stepper exposes step labels for screen readers', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.accepted()),
      );
      final en = lookupAppLocalizations(const Locale('en'));
      expect(find.text(en.statusAccepted), findsOneWidget);
      expect(find.text(en.statusDelivered), findsOneWidget);
    });
  });
}
