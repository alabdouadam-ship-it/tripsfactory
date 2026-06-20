import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// White-label seam for authentication options.
///
/// ## Apple requirement (App Store Review Guideline 4.8)
/// Apple requires that an iOS app providing **any** third-party or social login
/// (e.g. Google) **must also** provide **Sign in with Apple**. This product ships
/// with Sign in with Apple **not implemented**, so to stay App-Store-compliant
/// out of the box, social sign-in (Google) is **hidden on Apple platforms**
/// (iOS/macOS) by default. Android and other platforms show Google normally.
///
/// ### To enable social sign-in on iOS
/// 1. Implement **Sign in with Apple** (add the `sign_in_with_apple` package,
///    wire the Apple button's `onTap`, and enable the **Apple** provider in
///    Supabase — Apple Developer side: Service ID, key, return URLs).
/// 2. Set [appleSignInEnabled] to `true`. That re-enables the social section
///    (Apple **and** Google) on iOS/macOS.
///
/// See `docs/BACKEND_SETUP.md` (Part C) and `docs/STORE_SUBMISSION.md`.
class AuthConfig {
  AuthConfig._();

  /// Flip to `true` only after Sign in with Apple is fully implemented.
  static const bool appleSignInEnabled = false;

  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Show the Apple sign-in button (Apple platforms only, once enabled).
  static bool get showAppleButton => _isApplePlatform && appleSignInEnabled;

  /// Show the Google sign-in button. On Apple platforms it appears only when
  /// Apple Sign-In is enabled (guideline 4.8); elsewhere it always shows.
  static bool get showGoogleButton =>
      _isApplePlatform ? appleSignInEnabled : true;

  /// Whether any social sign-in button is shown — use to gate the
  /// "or continue with" divider / social section.
  static bool get showSocialSignIn => showGoogleButton || showAppleButton;
}
