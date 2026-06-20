import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/core/providers/locale_provider.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';

/// Provides AppLocalizations for the current locale.
/// Use in services that need localization without BuildContext.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return lookupAppLocalizations(locale);
});
