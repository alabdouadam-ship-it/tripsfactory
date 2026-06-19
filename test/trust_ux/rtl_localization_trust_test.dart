import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/widgets/trust_badge.dart';
import 'package:tripship/core/widgets/platform_secure_banner.dart';
import 'package:tripship/features/bookings/presentation/widgets/booking_progress_stepper.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import '../test_helpers/booking_fixture.dart';
import '../test_helpers/pump_app.dart';

void main() {
  group('RTL and localization trust', () {
    testWidgets('Arabic locale: TrustBadge renders without overflow', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(
        tester,
        TrustBadge.verified(),
        locale: const Locale('ar'),
        rtl: true,
      );
      expect(find.byKey(const Key('badge_verified_traveler')), findsOneWidget);
    });

    testWidgets('Arabic: PlatformSecureBanner.chat renders', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(
        tester,
        Builder(builder: (context) => PlatformSecureBanner.chat(context)),
        locale: const Locale('ar'),
        rtl: true,
      );
      expect(find.byKey(const Key('chat_security_banner')), findsOneWidget);
    });

    testWidgets('RTL: progress stepper renders without exception', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(
        tester,
        BookingProgressStepper(booking: BookingFixture.accepted()),
        locale: const Locale('ar'),
        rtl: true,
      );
      expect(find.byKey(const Key('booking_progress')), findsOneWidget);
    });

    testWidgets('Arabic localization: status strings resolve', (
      WidgetTester tester,
    ) async {
      final ar = lookupAppLocalizations(const Locale('ar'));
      expect(ar.verified, isNotEmpty);
      expect(ar.licenseExpiry, isNotEmpty);
    });
  });
}
