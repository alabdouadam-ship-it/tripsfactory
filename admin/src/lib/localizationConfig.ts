// White-label localization seam for the ADMIN console.
//
// The admin is an internal operator tool, so it does NOT need the full set of
// end-user app languages. A fork chooses which operator languages to offer here.
// Full dictionaries currently exist for English and Arabic (see i18n.tsx); to
// enable Arabic, add 'ar' to `supported`.
//
// Default: English only (Arabic available but off). The language switcher in
// Settings only renders the supported languages and hides entirely when there
// is just one.

export type AdminLanguage = 'en' | 'ar';

export const AdminLocalizationConfig = {
  /** Operator languages this fork offers. Default: English only. */
  supported: ['en'] as AdminLanguage[],
  /** The language the console starts in. */
  default: 'en' as AdminLanguage,
};

export function isAdminLanguageSupported(lang: string): lang is AdminLanguage {
  return (AdminLocalizationConfig.supported as string[]).includes(lang);
}
