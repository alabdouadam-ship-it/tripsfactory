import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('PreferencesService must be initialized in main()');
});

/// Service for managing app preferences using SharedPreferences
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Keys
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  /// Get saved theme mode
  ThemeMode getThemeMode() {
    final String? themeModeString = _prefs.getString(_themeKey);
    if (themeModeString == null) return ThemeMode.system;

    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == themeModeString,
      orElse: () => ThemeMode.system,
    );
  }

  /// Save theme mode
  Future<bool> setThemeMode(ThemeMode mode) async {
    return await _prefs.setString(_themeKey, mode.toString());
  }

  /// Get saved locale
  Locale? getLocale() {
    final String? localeCode = _prefs.getString(_localeKey);
    if (localeCode == null) return null;

    // Support for language codes like 'ar', 'en', 'ar_AE', etc.
    final parts = localeCode.split('_');
    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }

    return null;
  }

  /// Save locale
  Future<bool> setLocale(Locale locale) async {
    final String localeCode = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    return await _prefs.setString(_localeKey, localeCode);
  }

  /// Generic string getter (sync)
  String? getStringSync(String key) => _prefs.getString(key);

  /// Generic string getter
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  /// Generic string setter
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Generic bool getter
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  /// Generic bool setter
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// Generic int getter
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  /// Generic int setter
  Future<bool> setInt(String key, int value) async =>
      await _prefs.setInt(key, value);

  /// Remove a key
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Get list of saved emails for auto-complete (email only — no passwords stored)
  List<String> getSavedEmails() {
    return _prefs.getStringList('saved_emails') ?? [];
  }

  /// Save email address for auto-complete (does NOT save the password).
  /// Use the platform's secure credential store if password auto-fill is needed.
  Future<void> saveEmail(String email) async {
    final List<String> savedEmails = getSavedEmails();
    if (!savedEmails.contains(email)) {
      savedEmails.add(email);
      await _prefs.setStringList('saved_emails', savedEmails);
    }
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
