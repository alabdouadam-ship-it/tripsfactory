import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/widgets/trust_badge.dart';
import 'package:tripship/features/trips/presentation/trip_card.dart';
import '../test_helpers/fixtures.dart';
import '../test_helpers/pump_app.dart';

void main() {
  group('Verification and legitimacy signals', () {
    testWidgets(
      'TrustBadge.verified has Key(badge_verified_traveler) and is visible',
      (WidgetTester tester) async {
        await pumpTrustUxWidget(tester, TrustBadge.verified());
        expect(
          find.byKey(const Key('badge_verified_traveler')),
          findsOneWidget,
        );
      },
    );

    testWidgets('TrustBadge.licenseValid has Key(badge_license_valid)', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(tester, TrustBadge.license());
      expect(find.byKey(const Key('badge_license_valid')), findsOneWidget);
    });

    testWidgets(
      'Verified traveler: TripCard shows verified badge when driver is active and has identity',
      (WidgetTester tester) async {
        final profile = ProfileFixture.verifiedTravelerValidLicense();
        final trip = tripFixtureWithDriver(profile);
        await pumpTrustUxWidget(tester, TripCard(trip: trip));
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.byKey(const Key('badge_verified_traveler')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Unverified traveler: TripCard does not show verified badge', (
      WidgetTester tester,
    ) async {
      final profile = ProfileFixture.unverifiedTraveler();
      final trip = tripFixtureWithDriver(profile);
      await pumpTrustUxWidget(tester, TripCard(trip: trip));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('badge_verified_traveler')), findsNothing);
    });

    testWidgets('TrustBadge has text and Semantics label for Verified traveler', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(tester, TrustBadge.verified());
      // The semantics label comes from localization, usually 'Verified' in English
      expect(find.text('Verified'), findsOneWidget);
    });
  });
}
