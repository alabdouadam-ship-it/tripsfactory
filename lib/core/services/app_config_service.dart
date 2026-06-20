import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';
import 'package:tripsfactory/core/utils/logger.dart';

class OccasionalPopup {
  final bool active;
  final String? title;
  final String? titleAr;
  final String? body;
  final String? bodyAr;
  final String? imageUrl;
  final String? actionUrl;
  final String target; // 'all' | 'individuals' | 'drivers' | 'companies' | 'new_users'
  final DateTime? publishedAt;

  OccasionalPopup({
    required this.active,
    this.title,
    this.titleAr,
    this.body,
    this.bodyAr,
    this.imageUrl,
    this.actionUrl,
    this.target = 'all',
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
    'active': active,
    'title': title,
    'titleAr': titleAr,
    'body': body,
    'bodyAr': bodyAr,
    'imageUrl': imageUrl,
    'actionUrl': actionUrl,
    'target': target,
    'publishedAt': publishedAt?.toIso8601String(),
  };

  factory OccasionalPopup.fromJson(Map<String, dynamic> json) =>
      OccasionalPopup(
        active: json['active'] == true,
        title: json['title'] as String?,
        titleAr: json['titleAr'] as String?,
        body: json['body'] as String?,
        bodyAr: json['bodyAr'] as String?,
        imageUrl: json['imageUrl'] as String?,
        actionUrl: json['actionUrl'] as String?,
        target: (json['target'] as String?) ?? 'all',
        publishedAt: json['publishedAt'] is String
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
      );
}

class FirstLaunchPopup {
  final bool active;
  final String? title;
  final String? titleAr;
  final String? body;
  final String? bodyAr;
  final String? imageUrl;
  final String? actionUrl;
  final String target; // 'all' | 'individuals' | 'drivers' | 'companies' | 'new_users'
  final int version;

  FirstLaunchPopup({
    required this.active,
    this.title,
    this.titleAr,
    this.body,
    this.bodyAr,
    this.imageUrl,
    this.actionUrl,
    this.target = 'all',
    this.version = 0,
  });

  Map<String, dynamic> toJson() => {
    'active': active,
    'title': title,
    'titleAr': titleAr,
    'body': body,
    'bodyAr': bodyAr,
    'imageUrl': imageUrl,
    'actionUrl': actionUrl,
    'target': target,
    'version': version,
  };

  factory FirstLaunchPopup.fromJson(Map<String, dynamic> json) =>
      FirstLaunchPopup(
        active: json['active'] == true,
        title: json['title'] as String?,
        titleAr: json['titleAr'] as String?,
        body: json['body'] as String?,
        bodyAr: json['bodyAr'] as String?,
        imageUrl: json['imageUrl'] as String?,
        actionUrl: json['actionUrl'] as String?,
        target: (json['target'] as String?) ?? 'all',
        version: (json['version'] as int?) ?? 0,
      );
}

class AppConfig {
  final bool updateRequired;
  final String? forceUpdateMessage;
  final bool globalMessageActive;
  final String? globalMessageContent;
  final String? supportWhatsApp;

  /// Global app availability switch driven by the admin console.
  /// When false, the app shows a maintenance screen.
  final bool appOpen;
  final String? closedMessage;
  final String? closedMessageAr;

  /// Optional first-launch popup configured from the admin console.
  final FirstLaunchPopup? firstLaunchPopup;

  /// Optional occasional popup that admin can publish anytime.
  final OccasionalPopup? occasionalPopup;

  AppConfig({
    required this.updateRequired,
    this.forceUpdateMessage,
    this.globalMessageActive = false,
    this.globalMessageContent,
    this.supportWhatsApp,
    this.appOpen = true,
    this.closedMessage,
    this.closedMessageAr,
    this.firstLaunchPopup,
    this.occasionalPopup,
  });

  Map<String, dynamic> toJson() => {
    'updateRequired': updateRequired,
    'forceUpdateMessage': forceUpdateMessage,
    'globalMessageActive': globalMessageActive,
    'globalMessageContent': globalMessageContent,
    'supportWhatsApp': supportWhatsApp,
    'appOpen': appOpen,
    'closedMessage': closedMessage,
    'closedMessageAr': closedMessageAr,
    'firstLaunchPopup': firstLaunchPopup?.toJson(),
    'occasionalPopup': occasionalPopup?.toJson(),
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    updateRequired: json['updateRequired'] == true,
    forceUpdateMessage: json['forceUpdateMessage'] as String?,
    globalMessageActive: json['globalMessageActive'] == true,
    globalMessageContent: json['globalMessageContent'] as String?,
    supportWhatsApp: json['supportWhatsApp'] as String?,
    appOpen: json['appOpen'] == null ? true : json['appOpen'] == true,
    closedMessage: json['closedMessage'] as String?,
    closedMessageAr: json['closedMessageAr'] as String?,
    firstLaunchPopup: json['firstLaunchPopup'] is Map<String, dynamic>
        ? FirstLaunchPopup.fromJson(
            json['firstLaunchPopup'] as Map<String, dynamic>,
          )
        : null,
    occasionalPopup: json['occasionalPopup'] is Map<String, dynamic>
        ? OccasionalPopup.fromJson(
            json['occasionalPopup'] as Map<String, dynamic>,
          )
        : null,
  );
}

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  // Keep alive for the session — avoids re-fetching on every router redirect.
  // The 3h cache inside handles real freshness; invalidate manually if needed.
  ref.keepAlive();

  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  final preferences = ref.watch(preferencesServiceProvider);
  const cacheKey = 'app_config_cache_v2'; // Bumped key for JSON format
  const cacheTimeKey = 'app_config_fetched_at';

  try {
    // 1. Check Cache first
    final cachedData = preferences.getStringSync(cacheKey);
    final cachedAtStr = preferences.getStringSync(cacheTimeKey);

    if (cachedData != null && cachedAtStr != null) {
      final cachedAt = DateTime.tryParse(cachedAtStr);
      if (cachedAt != null &&
          DateTime.now().difference(cachedAt).inHours < 3) {
        try {
          final data = jsonDecode(cachedData) as Map<String, dynamic>;
          final cachedConfig = AppConfig.fromJson(data);
          
          // If app is closed in cache, always fetch fresh to check if it's now open
          if (!cachedConfig.appOpen) {
            StructuredLogger.info(
              'AppConfigService',
              'app closed in cache, fetching fresh config',
            );
          } else {
            return cachedConfig;
          }
        } catch (e) {
          StructuredLogger.warning(
            'AppConfigService',
            'failed to parse cached config',
          );
        }
      }
    }

    // 2. Fetch from Supabase
    final response = await Supabase.instance.client
        .from('app_settings')
        .select()
        .limit(1)
        .maybeSingle();

    if (response != null) {
      final minVersion = Platform.isIOS
          ? (response['ios_min_version'] as String?)
          : (response['android_min_version'] as String?);

      final message = response['force_update_message'] as String?;
      final isMsgActive = response['global_message_active'] as bool? ?? false;
      final msgContent = response['global_message_content'] as String?;
      final whatsapp = response['support_whatsapp'] as String?;
      final appOpen = response['app_open'] as bool? ?? true;
      final closedMessage = response['closed_message'] as String?;
      final closedMessageAr = response['closed_message_ar'] as String?;

      FirstLaunchPopup? popup;
      final popupActive =
          response['first_launch_popup_active'] as bool? ?? false;
      if (popupActive) {
        popup = FirstLaunchPopup(
          active: true,
          title: response['first_launch_popup_title'] as String?,
          titleAr: response['first_launch_popup_title_ar'] as String?,
          body: response['first_launch_popup_body'] as String?,
          bodyAr: response['first_launch_popup_body_ar'] as String?,
          imageUrl: response['first_launch_popup_image_url'] as String?,
          actionUrl: response['first_launch_popup_action_url'] as String?,
          target:
              (response['first_launch_popup_target'] as String?) ?? 'all',
          version: (response['first_launch_popup_version'] as int?) ?? 0,
        );
      }

      OccasionalPopup? occasionalPopup;
      final occasionalActive =
          response['occasional_popup_active'] as bool? ?? false;
      if (occasionalActive) {
        final publishedAtStr =
            response['occasional_popup_published_at'] as String?;
        occasionalPopup = OccasionalPopup(
          active: true,
          title: response['occasional_popup_title'] as String?,
          titleAr: response['occasional_popup_title_ar'] as String?,
          body: response['occasional_popup_body'] as String?,
          bodyAr: response['occasional_popup_body_ar'] as String?,
          imageUrl: response['occasional_popup_image_url'] as String?,
          actionUrl: response['occasional_popup_action_url'] as String?,
          target: (response['occasional_popup_target'] as String?) ?? 'all',
          publishedAt: publishedAtStr != null
              ? DateTime.tryParse(publishedAtStr)
              : null,
        );
      }

      final isUpdateRequired = minVersion != null
          ? _isUpdateRequired(currentVersion, minVersion)
          : false;

      final config = AppConfig(
        updateRequired: isUpdateRequired,
        forceUpdateMessage: message,
        globalMessageActive: isMsgActive,
        globalMessageContent: msgContent,
        supportWhatsApp: whatsapp,
        appOpen: appOpen,
        closedMessage: closedMessage,
        closedMessageAr: closedMessageAr,
        firstLaunchPopup: popup,
        occasionalPopup: occasionalPopup,
      );

      // Cache for 3 hours (reduced from 24h for faster occasional popup delivery)
      await preferences.setString(cacheKey, jsonEncode(config.toJson()));
      await preferences.setString(
        cacheTimeKey,
        DateTime.now().toIso8601String(),
      );

      return config;
    }
  } catch (e, st) {
    StructuredLogger.error('AppConfigService', 'fetch config failed', e, st);
  }

  return AppConfig(updateRequired: false);
});

bool _isUpdateRequired(String current, String required) {
  // Semver comparison supporting any number of version parts (e.g. 1.0.0.1)
  final currParts = current
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();
  final reqParts = required
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();

  final maxLen = currParts.length > reqParts.length
      ? currParts.length
      : reqParts.length;

  for (var i = 0; i < maxLen; i++) {
    final c = i < currParts.length ? currParts[i] : 0;
    final r = i < reqParts.length ? reqParts[i] : 0;
    if (c < r) return true;
    if (c > r) return false;
  }
  return false;
}
