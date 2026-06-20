import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:share_plus/share_plus.dart';
import 'package:tripsfactory/core/config/app_constants.dart';
import 'package:tripsfactory/core/config/store_links.dart';

/// Share a trip with a friend. Generates a shareable URL that works with
/// deep linking (app opens to trip details) or store fallback.
Future<void> shareTrip(String tripId) async {
  final url = '${AppConstants.tripBaseUrl}/$tripId';
  await SharePlus.instance.share(
    ShareParams(text: url, subject: 'Trip on TripsFactory'),
  );
}

/// Shares the app store link. Uses Google Play on Android, App Store on iOS.
Future<void> shareApp() async {
  final url = defaultTargetPlatform == TargetPlatform.iOS
      ? appStoreUrl
      : playStoreUrl;
  await SharePlus.instance.share(
    ShareParams(
      text: url,
      subject: 'TripsFactory - منصة الربط بين المرسلين والمسافرين',
    ),
  );
}
