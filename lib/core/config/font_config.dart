import 'package:flutter/widgets.dart';
import 'package:tripsfactory/core/config/brand_config.dart';
import 'package:tripsfactory/core/theme/app_theme.dart';

/// White-label typography seam.
///
/// The app resolves the font family for the active locale + theme through
/// [resolve]. By default every language and theme uses [defaultFamily]
/// (`BrandConfig.fontFamily`). A fork can override the font:
///   * per language — e.g. a script-specific font for Arabic, and
///   * per theme — e.g. a display font for a particular look.
///
/// Family names are [Google Fonts](https://fonts.google.com) family names
/// (the same source the base theme uses). Per-language overrides win over
/// per-theme overrides, which win over the default.
class FontConfig {
  FontConfig._();

  /// The default font for all languages/themes unless overridden below.
  static const String defaultFamily = BrandConfig.fontFamily;

  /// Per-language overrides, keyed by language code. e.g. `{'ar': 'Cairo'}`.
  static const Map<String, String> perLanguage = <String, String>{};

  /// Per-theme overrides. e.g. `{AppThemeMode.desertGold: 'Tajawal'}`.
  static const Map<AppThemeMode, String> perTheme = <AppThemeMode, String>{};

  /// Resolves the font family: language override > theme override > default.
  static String resolve(Locale locale, AppThemeMode theme) =>
      perLanguage[locale.languageCode] ?? perTheme[theme] ?? defaultFamily;
}
