import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/providers/app_localizations_provider.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// Returns [AppLocalizations] for [context], or fallback from [ref] when
/// context is not yet under the localizations overlay (avoids crash from [AppLocalizations.of(context)!]).
/// Use in Consumer widgets.
AppLocalizations localizationsOf(BuildContext context, WidgetRef ref) {
  return AppLocalizations.of(context) ?? ref.read(appLocalizationsProvider);
}

/// Returns [AppLocalizations] for [context], or lookup by locale when not in overlay.
/// Use in StatelessWidget or when ref is not available.
AppLocalizations localizationsOfContext(BuildContext context) {
  return AppLocalizations.of(context) ?? lookupAppLocalizations(Localizations.localeOf(context));
}
