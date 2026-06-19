/// White-label geography seam.
///
/// The marketplace splits routes into **internal** (both endpoints inside the
/// "home" country) and **external** (crossing the home country's border). This
/// seam lets a fork:
///   * set the home country's ISO code (the PRIMARY way it's matched) plus its
///     display names (English + Arabic, used as a fallback and in messages), and
///   * choose whether an external route must keep the home country on exactly
///     one side ([externalRequiresHomeCountryOnOneSide]).
///
/// Matching prefers the ISO `country_code` (robust, language-independent) and
/// falls back to the country name only when no code is available on the record.
class GeographyConfig {
  GeographyConfig._();

  /// Canonical ISO 3166 alpha-2 code of the home country. The PRIMARY match key.
  static const String homeCountryCode = 'AE';

  /// All ISO codes treated as the home country (alpha-2 + any alpha-3 variant).
  static const Set<String> homeCountryCodes = <String>{'AE', 'ARE'};

  /// Home country name in English (fallback match + display).
  static const String homeCountryNameEn = 'United Arab Emirates';

  /// Home country name in Arabic (fallback match + display).
  static const String homeCountryNameAr = 'الإمارات العربية المتحدة';

  /// Extra spellings to also treat as the home country (name fallback only).
  /// Latin compared case-insensitively; Arabic compared as-is.
  static const List<String> homeCountryAliases = <String>['uae', 'الإمارات'];

  /// When true, an EXTERNAL route must have the home country on exactly one
  /// side (origin XOR destination). When false, external means "not purely
  /// internal" — any route not entirely inside the home country is allowed.
  static const bool externalRequiresHomeCountryOnOneSide = true;

  /// PRIMARY check: whether an ISO country code is the home country.
  static bool isHomeCountryCode(String? code) {
    if (code == null) return false;
    final c = code.trim().toUpperCase();
    return c.isNotEmpty && homeCountryCodes.contains(c);
  }

  /// FALLBACK check: whether the country name (either language) is the home
  /// country. Used only when no ISO code is available on the record.
  static bool isHomeCountryName(String? nameEn, String? nameAr) {
    final en = nameEn?.trim().toLowerCase();
    final ar = nameAr?.trim();
    if (en != null && en.isNotEmpty && en == homeCountryNameEn.toLowerCase()) {
      return true;
    }
    if (ar != null && ar.isNotEmpty && ar == homeCountryNameAr) return true;
    if (en != null && en.isNotEmpty && homeCountryAliases.contains(en)) {
      return true;
    }
    if (ar != null && ar.isNotEmpty && homeCountryAliases.contains(ar)) {
      return true;
    }
    return false;
  }

  /// Code-first matcher for a country/location record: uses the ISO code when
  /// present, otherwise falls back to the names.
  static bool isHomeCountry({String? code, String? nameEn, String? nameAr}) {
    if (code != null && code.trim().isNotEmpty) return isHomeCountryCode(code);
    return isHomeCountryName(nameEn, nameAr);
  }

  /// The home country name to show in messages for the given [localeCode].
  static String homeCountryName(String localeCode) =>
      localeCode == 'ar' ? homeCountryNameAr : homeCountryNameEn;
}
