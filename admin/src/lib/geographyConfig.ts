// White-label geography seam for the admin panel.
//
// Mirrors the app's `lib/core/config/geography_config.dart`. The marketplace
// splits routes into internal (both endpoints in the home country) and external
// (crossing its border). A fork sets its home country here, in one place, and
// every admin comparison + the route messages follow it.

export const GeographyConfig = {
  /** Home country name in English (as it appears in the locations data). */
  homeCountryNameEn: 'United Arab Emirates',
  /** Home country name in Arabic (as it appears in the locations data). */
  homeCountryNameAr: 'الإمارات العربية المتحدة',
  /** Canonical ISO code assigned to home-country locations when matched by name. */
  homeCountryCode: 'AE',
  /** Country codes treated as the home country. */
  homeCountryCodes: ['AE', 'ARE'],
  /** Extra lowercased name spellings to also treat as the home country. */
  homeCountryAliases: ['uae', 'الإمارات'],
  /** Whether an external route must keep the home country on exactly one side. */
  externalRequiresHomeCountryOnOneSide: true,
  /** Default map center [lat, lng] (home country — Dubai). */
  defaultMapCenter: [25.2048, 55.2708] as [number, number],
};

/** The home country name to show in messages for the given locale. */
export function homeCountryName(locale: string): string {
  return locale === 'ar'
    ? GeographyConfig.homeCountryNameAr
    : GeographyConfig.homeCountryNameEn;
}

/** Whether the given country names denote the home country (name match). */
export function isHomeCountryName(
  nameEn?: string | null,
  nameAr?: string | null,
): boolean {
  const names = [nameEn, nameAr]
    .filter((v): v is string => v != null && v !== '')
    .map((v) => v.trim().toLowerCase());
  const targets = [
    GeographyConfig.homeCountryNameEn.toLowerCase(),
    GeographyConfig.homeCountryNameAr.toLowerCase(),
    ...GeographyConfig.homeCountryAliases.map((a) => a.toLowerCase()),
  ];
  return names.some((n) => targets.some((target) => n === target));
}

/** Whether a location is in the home country (by country code or names). */
export function isHomeCountryLocation(
  loc?:
    | {
        country_code?: string | null;
        country_name_en?: string | null;
        country_name_ar?: string | null;
      }
    | null,
): boolean {
  if (!loc) return false;
  const code = loc.country_code?.trim?.().toUpperCase?.();
  if (code && GeographyConfig.homeCountryCodes.includes(code)) return true;
  return isHomeCountryName(loc.country_name_en, loc.country_name_ar);
}
