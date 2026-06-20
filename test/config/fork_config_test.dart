import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/config/brand_config.dart';
import 'package:tripsfactory/core/config/font_config.dart';
import 'package:tripsfactory/core/config/geography_config.dart';
import 'package:tripsfactory/core/config/localization_config.dart';
import 'package:tripsfactory/core/theme/app_theme.dart';

/// Guards that `fork.config.json` stays the single, reviewable source of truth
/// for a fork's configuration: its `brand`, `localization`, `theme` and `font`
/// blocks must match the Dart seams (`BrandConfig`, `LocalizationConfig`,
/// `AppTheme`/`ThemeNotifier`, `FontConfig`) exactly. If a fork edits a seam but
/// forgets the descriptor (or vice versa), this test fails — keeping them in
/// lockstep.
void main() {
  late Map<String, dynamic> config;
  late Map<String, dynamic> brand;

  setUpAll(() {
    final file = File('fork.config.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'fork.config.json must exist at the repo root',
    );
    config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    brand = config['brand'] as Map<String, dynamic>;
  });

  test('fork.config.json brand block matches BrandConfig', () {
    expect(brand['name'], BrandConfig.brandName);
    expect(brand['androidPackageId'], BrandConfig.androidPackageId);
    expect(brand['authScheme'], BrandConfig.authScheme);
    expect(brand['contentScheme'], BrandConfig.contentScheme);
    expect(brand['webBaseUrl'], BrandConfig.webBaseUrl);
    expect(brand['appStoreUrl'], BrandConfig.appStoreUrl);
    expect(brand['fontFamily'], BrandConfig.fontFamily);
    expect(brand['notificationChannelId'], BrandConfig.notificationChannelId);
    expect(
      brand['notificationChannelName'],
      BrandConfig.notificationChannelName,
    );
    expect(
      brand['notificationSoundAndroid'],
      BrandConfig.notificationSoundAndroid,
    );
    expect(brand['notificationSoundIos'], BrandConfig.notificationSoundIos);
    expect(
      brand['supportWhatsAppFallback'],
      BrandConfig.supportWhatsAppFallback,
    );
    expect(brand['logoAsset'], BrandConfig.logoAsset);
  });

  test('descriptor declares the per-fork backend and native checklists', () {
    // These don't move with a Dart constant; the descriptor documents them so
    // a fork has a complete, single-file checklist.
    expect(config['backend'], isA<Map<String, dynamic>>());
    expect(config['nativeChecklist'], isA<Map<String, dynamic>>());
  });

  test('fork.config.json localization block matches LocalizationConfig', () {
    final loc = config['localization'] as Map<String, dynamic>;
    expect(
      (loc['supported'] as List).cast<String>(),
      LocalizationConfig.supported.map((l) => l.languageCode).toList(),
      reason: 'localization.supported must match LocalizationConfig.supported',
    );
    expect(
      loc['default'],
      LocalizationConfig.defaultLocale.languageCode,
      reason: 'localization.default must match LocalizationConfig.defaultLocale',
    );
  });

  test('fork.config.json theme block matches AppTheme', () {
    final theme = config['theme'] as Map<String, dynamic>;
    expect(
      (theme['supported'] as List).cast<String>(),
      AppTheme.supportedThemes.map((m) => m.name).toList(),
      reason: 'theme.supported must match AppTheme.supportedThemes (and order)',
    );
    expect(
      theme['default'],
      ThemeNotifier.defaultThemeMode.name,
      reason: 'theme.default must match ThemeNotifier.defaultThemeMode',
    );
  });

  test('fork.config.json font block matches FontConfig', () {
    final font = config['font'] as Map<String, dynamic>;
    expect(font['default'], FontConfig.defaultFamily);
    expect(
      (font['perLanguage'] as Map).map(
        (k, v) => MapEntry(k as String, v as String),
      ),
      FontConfig.perLanguage,
      reason: 'font.perLanguage must match FontConfig.perLanguage',
    );
    expect(
      (font['perTheme'] as Map).map(
        (k, v) => MapEntry(k as String, v as String),
      ),
      FontConfig.perTheme.map((k, v) => MapEntry(k.name, v)),
      reason: 'font.perTheme must match FontConfig.perTheme',
    );
  });

  test('fork.config.json geography block matches GeographyConfig', () {
    final geo = config['geography'] as Map<String, dynamic>;
    expect(geo['homeCountryCode'], GeographyConfig.homeCountryCode);
    expect(geo['homeCountryNameEn'], GeographyConfig.homeCountryNameEn);
    expect(geo['homeCountryNameAr'], GeographyConfig.homeCountryNameAr);
    expect(
      geo['externalRequiresHomeCountryOnOneSide'],
      GeographyConfig.externalRequiresHomeCountryOnOneSide,
    );
  });
}
