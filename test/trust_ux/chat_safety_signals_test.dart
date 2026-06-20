import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/widgets/platform_secure_banner.dart';
import '../test_helpers/pump_app.dart';

void main() {
  group('Chat safety signals', () {
    testWidgets('PlatformSecureBanner.chat has Key(chat_security_banner)', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(
        tester,
        Builder(builder: (context) => PlatformSecureBanner.chat(context)),
      );
      expect(find.byKey(const Key('chat_security_banner')), findsOneWidget);
    });

    testWidgets('Chat security banner shows secured/moderated message', (
      WidgetTester tester,
    ) async {
      await pumpTrustUxWidget(
        tester,
        Builder(builder: (context) => PlatformSecureBanner.chat(context)),
      );
      expect(
        find.text('Conversation secured and moderated by TripsFactory.'),
        findsOneWidget,
      );
    });
  });
}
