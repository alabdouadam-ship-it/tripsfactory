/// Demo-mode seam.
///
/// When enabled, the app launches with **no backend** (no Supabase/Firebase
/// required) and presents a logged-in experience seeded with in-memory mock
/// data, so an evaluator can explore the UI immediately.
///
/// Enable it at build/run time with a dart-define:
///
/// ```
/// flutter run        --dart-define=DEMO_MODE=true
/// flutter build apk  --dart-define=DEMO_MODE=true
/// ```
///
/// It defaults to **false**, so normal builds and the test suite are
/// completely unaffected — every demo code path is gated behind [enabled].
class DemoConfig {
  DemoConfig._();

  /// Whether demo mode is active (compile-time constant from `--dart-define`).
  static const bool enabled =
      bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  /// Stable id used for the seeded demo user.
  static const String demoUserId = '00000000-0000-4000-8000-0000000000d0';

  /// Placeholder Supabase values used only so the client can initialize in
  /// demo mode. No real network calls are expected to succeed.
  static const String placeholderSupabaseUrl = 'https://demo.tripsfactory.invalid';
  static const String placeholderSupabaseAnonKey = 'demo-anon-key';
}
