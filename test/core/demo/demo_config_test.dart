import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/config/demo_config.dart';

void main() {
  group('DemoConfig', () {
    test('demo mode is OFF by default (no --dart-define=DEMO_MODE)', () {
      // Guards against accidentally shipping a build with demo mode hardcoded
      // on. Demo code paths in bootstrap/main/app are gated behind this flag,
      // so when it is false the app behaves exactly as in production.
      expect(DemoConfig.enabled, isFalse);
    });

    test('demo user id is a stable, non-empty constant', () {
      expect(DemoConfig.demoUserId, isNotEmpty);
    });
  });
}
