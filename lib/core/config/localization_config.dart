import 'package:flutter/widgets.dart';

/// White-label localization seam.
///
/// A fork controls which languages its app ships and which one is the default
/// from here. The app reads [supported] for the selectable language list and
/// [defaultLocale] for the first-launch language. Layout direction (RTL/LTR)
/// is derived automatically from the language code, so picking an RTL default
/// such as Arabic just works.
///
/// To ship fewer languages, trim [supported] (keep it a subset of [available]).
/// To add a brand-new language, add its `Locale` to [available] AND create a
/// matching `lib/l10n/app_<code>.arb`, then run `flutter gen-l10n`.
///
/// Translation status: Arabic and English are first-class. French, Turkish, and
/// Spanish (`app_fr/tr/es.arb`) are **machine-generated** — have a native
/// speaker review them before a production release (each file is marked with
/// `@@x-translation-status`).
class LocalizationConfig {
  LocalizationConfig._();

  /// Every language the app ships translations for. Each must have a matching
  /// `lib/l10n/app_<code>.arb` file (untranslated keys fall back to English).
  static const List<Locale> available = <Locale>[
    Locale('ar'), // العربية
    Locale('en'), // English
    Locale('fr'), // Français
    Locale('tr'), // Türkçe
    Locale('es'), // Español
  ];

  /// The subset a fork enables. Default: all of [available].
  static const List<Locale> supported = available;

  /// The language used on first launch, before the user chooses one.
  /// If this is an RTL language, the whole app lays out right-to-left.
  static const Locale defaultLocale = Locale('en');

  /// Language codes that render right-to-left.
  static const Set<String> rtlLanguageCodes = <String>{'ar', 'fa', 'he', 'ur'};

  static bool isRtl(Locale locale) =>
      rtlLanguageCodes.contains(locale.languageCode);

  /// Whether this fork supports [locale] (matched by language code).
  static bool isSupported(Locale locale) =>
      supported.any((l) => l.languageCode == locale.languageCode);

  /// The supported locale whose language code is [code], or null.
  static Locale? byCode(String code) {
    for (final l in supported) {
      if (l.languageCode == code) return l;
    }
    return null;
  }
}
