import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/theme/tripsfactory_design_tokens.dart';
import 'package:tripsfactory/core/widgets/trust_badge.dart';
import 'package:tripsfactory/core/widgets/platform_secure_banner.dart';
import '../test_helpers/pump_app.dart';

void main() {
  group('Visual consistency via design tokens', () {
    testWidgets('TripsFactoryDesignTokens has standardized border radii', (
      WidgetTester tester,
    ) async {
      expect(TripsFactoryDesignTokens.borderRadiusSmall, isNotNull);
      expect(TripsFactoryDesignTokens.borderRadiusMedium, isNotNull);
      expect(TripsFactoryDesignTokens.borderRadiusLarge, isNotNull);
      expect(TripsFactoryDesignTokens.borderRadiusSmall.topLeft.x, 8);
      expect(TripsFactoryDesignTokens.borderRadiusMedium.topLeft.x, 16);
      expect(TripsFactoryDesignTokens.borderRadiusLarge.topLeft.x, 24);
    });

    testWidgets('Shadow levels exist and are list', (
      WidgetTester tester,
    ) async {
      expect(TripsFactoryDesignTokens.shadowLevel0, isEmpty);
      await pumpTrustUxWidget(tester, TrustBadge.verified());
      final context = tester.element(find.byType(TrustBadge));
      expect(TripsFactoryDesignTokens.shadowLevel1(context), isA<List<BoxShadow>>());
      expect(TripsFactoryDesignTokens.shadowLevel2(context), isA<List<BoxShadow>>());
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
