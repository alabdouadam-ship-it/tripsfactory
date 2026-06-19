/// Single source of truth for **non-localized brand identity**.
///
/// This is the white-label seam: forking the app to a new brand/domain should
/// only require editing this file (plus assets, `.env`, and the native package
/// identifiers — see docs/BACKEND_SETUP.md / CORE.md). Anything that is user-facing
/// *copy* belongs in the ARB localization files, not here. Anything that is a
/// runtime, admin-tunable value (support number, global banners) belongs in
/// `app_settings` / `AppConfigService`; the values here are compile-time
/// defaults and fallbacks.
///
/// Fields are `static const` so they can be used in `const` contexts (e.g.
/// notification channel definitions).
class BrandConfig {
  BrandConfig._();

  // ── Identity ──────────────────────────────────────────────────────────────
  /// Internal/fallback brand name. User-facing title comes from
  /// `AppLocalizations.appTitle` (localized); use this only where no
  /// `BuildContext` is available.
  static const String brandName = 'TripShip';

  /// Android application id. NOTE: the authoritative value lives in the native
  /// build config (`android/app/build.gradle.kts`); this mirror is used for
  /// store links and reference only. Keep them in sync when forking.
  static const String androidPackageId = 'com.tripship.app';

  // ── Deep links ──────────────────────────────────────────────────────────--
  /// Scheme used for Supabase auth callbacks (password reset / OAuth login).
  /// Must match the redirect URLs configured in the Supabase dashboard and the
  /// native intent filters / URL types.
  static const String authScheme = 'io.supabase.tripship';

  /// Scheme used for in-app content deep links (`<scheme>://trip/{id}`, etc.).
  static const String contentScheme = 'tripship';

  static const String authCallbackReset = '$authScheme://reset-callback';
  static const String authCallbackLogin = '$authScheme://login-callback';

  // ── Web / legal links ───────────────────────────────────────────────────--
  /// Base URL for shareable content links and legal pages (privacy/terms).
  /// Replace with the fork's own Firebase Hosting / domain.
  static const String webBaseUrl = 'https://tripship-legal.web.app';

  // ── Store links ─────────────────────────────────────────────────────────--
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';
  static const String appStoreUrl =
      'https://apps.apple.com/app/tripship/id000000000';

  // ── Notifications ───────────────────────────────────────────────────────--
  /// Android notification channel id. Channels are immutable once created on a
  /// device, so changing the sound requires a NEW id.
  static const String notificationChannelId = 'tripship_notification_v1';
  static const String notificationChannelName = 'TripShip Notifications';

  /// Android raw resource name (no extension) — `android/app/src/main/res/raw/`.
  /// NOTE: the bundled sound asset files are still named `tripship_notification.*`
  /// (the internal asset codename). To fully rename them, rename the files in
  /// `android/app/src/main/res/raw/` and `ios/Runner/`, update the iOS project
  /// reference, and change these two values to match.
  static const String notificationSoundAndroid = 'tripship_notification';

  /// iOS bundled sound file name (with extension).
  static const String notificationSoundIos = 'tripship_notification.wav';

  // ── Support ─────────────────────────────────────────────────────────────--
  /// Fallback WhatsApp support number used when the admin-configured
  /// `app_settings.support_whatsapp` is empty.
  static const String supportWhatsAppFallback = '+971933123456';

  // ── Visual identity ─────────────────────────────────────────────────────--
  /// Google Fonts family used across the app typography.
  static const String fontFamily = 'Public Sans';

  /// Short uppercase tagline shown under the brand name on the splash screen.
  static const String splashTagline = 'LOGISTICS';

  /// The default theme on first launch is defined in `AppTheme.defaultThemeMode`
  /// (kept in the theme layer to avoid an import cycle). Listed here as the
  /// canonical white-label checklist item.

  // ── Brand assets ────────────────────────────────────────────────────────--
  /// Primary logo / launcher image shown on splash and auth headers.
  static const String logoAsset = 'assets/icon/icon.png';

  /// App icon source (also referenced by `flutter_launcher_icons.yaml`).
  static const String appIconAsset = 'assets/icon/icon.png';
}
