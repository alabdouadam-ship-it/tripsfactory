// ignore_for_file: deprecated_member_use
import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:tripsfactory/core/config/brand_config.dart';
import 'package:tripsfactory/core/config/localization_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/core/theme/app_theme.dart';
import 'package:tripsfactory/core/providers/locale_provider.dart';
import 'package:tripsfactory/core/providers/text_scale_provider.dart';
import 'package:tripsfactory/core/services/app_review_service.dart';
import 'package:tripsfactory/core/services/share_service.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/services/app_config_service.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tripsfactory/core/config/app_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final textScale = ref.watch(textScaleProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          _buildSectionHeader(context, localizations.language),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (final loc in LocalizationConfig.supported)
                  RadioListTile<String>(
                    title: Text(_languageName(loc.languageCode, localizations)),
                    value: loc.languageCode,
                    groupValue: currentLocale.languageCode,
                    onChanged: (_) =>
                        ref.read(localeProvider.notifier).setLocale(loc),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Text Size Section
          _buildSectionHeader(context, localizations.textSize),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                RadioListTile<TextScaleOption>(
                  title: Text(localizations.textSizeSmall),
                  value: TextScaleOption.small,
                  groupValue: textScale,
                  onChanged: (_) => ref
                      .read(textScaleProvider.notifier)
                      .setScale(TextScaleOption.small),
                ),
                RadioListTile<TextScaleOption>(
                  title: Text(localizations.textSizeNormal),
                  value: TextScaleOption.normal,
                  groupValue: textScale,
                  onChanged: (_) => ref
                      .read(textScaleProvider.notifier)
                      .setScale(TextScaleOption.normal),
                ),
                RadioListTile<TextScaleOption>(
                  title: Text(localizations.textSizeLarge),
                  value: TextScaleOption.large,
                  groupValue: textScale,
                  onChanged: (_) => ref
                      .read(textScaleProvider.notifier)
                      .setScale(TextScaleOption.large),
                ),
                RadioListTile<TextScaleOption>(
                  title: Text(localizations.textSizeExtraLarge),
                  value: TextScaleOption.extraLarge,
                  groupValue: textScale,
                  onChanged: (_) => ref
                      .read(textScaleProvider.notifier)
                      .setScale(TextScaleOption.extraLarge),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // Privacy & Safety
          _buildSectionHeader(context, localizations.privacyAndSafety),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: Text(localizations.blockedUsers),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.blockedUsers),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Management
          _buildSectionHeader(context, localizations.account),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: Text(localizations.documents),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.documents),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Help & Support
          _buildSectionHeader(context, localizations.helpAndSupport),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(localizations.contactSupport),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.support),
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined, color: Colors.green),
            title: Text(localizations.whatsappSupport),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final configAsync = ref.read(appConfigProvider);
              final phoneNumber =
                  configAsync.value?.supportWhatsApp ?? BrandConfig.supportWhatsAppFallback;
              final url =
                  'https://wa.me/${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(localizations.rateApp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(appReviewServiceProvider).openStoreListing(),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(localizations.shareApp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => shareApp(),
          ),
          const SizedBox(height: 24),

          // About TripsFactory Section
          _buildSectionHeader(context, localizations.aboutTripsFactory),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon and Name
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.appTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<String>(
                              future: _getAppVersion(),
                              builder: (context, snapshot) {
                                return Text(
                                  '${localizations.appVersion}: ${snapshot.data ?? '1.0.0'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    localizations.aboutTripsFactoryDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Legal Section
          _buildSectionHeader(context, localizations.legal),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(localizations.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _launchLegalUrl(
                    AppConstants.privacyPolicyUrl(currentLocale.languageCode),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(localizations.termsOfService),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _launchLegalUrl(
                    AppConstants.termsOfServiceUrl(currentLocale.languageCode),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme Section
          _buildSectionHeader(context, localizations.theme),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AppTheme.supportedThemes.length,
            itemBuilder: (context, index) {
              final mode = AppTheme.supportedThemes[index];
              final themeData = AppTheme.getTheme(mode);
              final isSelected = currentTheme == mode;

              return InkWell(
                onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeData.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 3,
                          )
                        : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Color Circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: themeData.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getThemeName(mode, localizations),
                        style: TextStyle(
                          color: themeData.textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _getThemeName(AppThemeMode mode, AppLocalizations localizations) {
    switch (mode) {
      case AppThemeMode.tripsfactoryDark:
        return localizations.themeDark;
      case AppThemeMode.tripsfactoryLight:
        return localizations.themeLight;
      case AppThemeMode.desertGold:
        return localizations.themeDesert;
      case AppThemeMode.oasisGreen:
        return localizations.themeOasis;
      case AppThemeMode.skylineBlue:
        return localizations.themeSkyline;
      case AppThemeMode.limestoneGray:
        return localizations.themeLimestone;
      case AppThemeMode.midnightPurple:
        return localizations.themeMidnight;
      case AppThemeMode.oceanTeal:
        return localizations.themeOcean;
      case AppThemeMode.steelGray:
        return localizations.themeSteel;
    }
  }

  String _languageName(String code, AppLocalizations l) {
    switch (code) {
      case 'ar':
        return l.arabic;
      case 'en':
        return l.english;
      case 'fr':
        return l.french;
      case 'tr':
        return l.turkish;
      case 'es':
        return l.spanish;
      default:
        return code;
    }
  }

  Future<void> _launchLegalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        StructuredLogger.error(
          'SettingsScreen',
          'Could not silently launch URL: $url',
          null,
          null,
        );
      }
    } catch (e, st) {
      StructuredLogger.error(
        'SettingsScreen',
        'Failed to launch URL: $url',
        e,
        st,
      );
    }
  }

  Future<String> _getAppVersion() async {
    try {
      // Import package_info_plus at the top of the file
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return '1.0.0+1';
    }
  }
}
