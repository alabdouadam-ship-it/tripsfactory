import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/theme/tripship_design_tokens.dart';
import 'package:tripship/core/widgets/trust_badge.dart';
import 'package:tripship/core/widgets/platform_secure_banner.dart';
import '../test_helpers/pump_app.dart';

void main() {
  group('Visual consistency via design tokens', () {
    testWidgets('TripShipDesignTokens has standardized border radii', (
      WidgetTester tester,
    ) async {
      expect(TripShipDesignTokens.borderRadiusSmall, isNotNull);
      expect(TripShipDesignTokens.borderRadiusMedium, isNotNull);
      expect(TripShipDesignTokens.borderRadiusLarge, isNotNull);
      expect(TripShipDesignTokens.borderRadiusSmall.topLeft.x, 8);
      expect(TripShipDesignTokens.borderRadiusMedium.topLeft.x, 16);
      expect(TripShipDesignTokens.borderRadiusLarge.topLeft.x, 24);
    });

    testWidgets('Shadow levels exist and are list', (
      WidgetTester tester,
    ) async {
      expect(TripShipDesignTokens.shadowLevel0, isEmpty);
      await pumpTrustUxWidget(tester, TrustBadge.verified());
      final context = tester.element(find.byType(TrustBadge));
      expect(TripShipDesignTokens.shadowLevel1(context), isA<List<BoxShadow>>());
      expect(TripShipDesignTokens.shadowLevel2(context), isA<List<BoxShadow>>());
    });

    testWidgets(
      'TrustBadge and PlatformSecureBanner use consistent radii (structure)',
      (WidgetTester tester) async {
        await pumpTrustUxWidget(
          tester,
          const Column(
            children: [
              TrustBadge(variant: TrustBadgeVariant.verified),
              Builder(builder: PlatformSecureBanner.chat),
            ],
          ),
        );
        expect(find.byType(TrustBadge), findsOneWidget);
        expect(find.byType(PlatformSecureBanner), findsOneWidget);
      },
    );
  });
}
