import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/config/localization_config.dart';
import 'package:tripship/core/services/preferences_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final PreferencesService _prefsService;

  LocaleNotifier(this._prefsService)
    : super(LocalizationConfig.defaultLocale) {
    _loadLocale();
  }

  void _loadLocale() {
    final savedLocale = _prefsService.getLocale();
    // Only restore a saved locale this fork still supports; otherwise keep the
    // configured default.
    if (savedLocale != null && LocalizationConfig.isSupported(savedLocale)) {
      state = savedLocale;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!LocalizationConfig.isSupported(locale)) return;
    state = locale;
    await _prefsService.setLocale(locale);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return LocaleNotifier(prefsService);
});
