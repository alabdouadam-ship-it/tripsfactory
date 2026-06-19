import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/config/brand_config.dart';
import 'package:tripship/core/config/app_constants.dart';
import 'package:tripship/core/config/store_links.dart';

void main() {
  group('BrandConfig white-label seam', () {
    test('auth callback URLs derive from the auth scheme', () {
      expect(
        BrandConfig.authCallbackReset,
        '${BrandConfig.authScheme}://reset-callback',
      );
      expect(
        BrandConfig.authCallbackLogin,
        '${BrandConfig.authScheme}://login-callback',
      );
    });

    test('AppConstants delegates brand values to BrandConfig', () {
      expect(AppConstants.baseUrl, BrandConfig.webBaseUrl);
      expect(AppConstants.authCallbackReset, BrandConfig.authCallbackReset);
      expect(AppConstants.authCallbackLogin, BrandConfig.authCallbackLogin);
    });

    test('store links delegate to BrandConfig', () {
      expect(playStoreUrl, BrandConfig.playStoreUrl);
      expect(appStoreUrl, BrandConfig.appStoreUrl);
    });

    test('Play Store URL targets the configured Android package id', () {
      expect(BrandConfig.playStoreUrl, contains(BrandConfig.androidPackageId));
    });

    test('brand identity fields are non-empty', () {
      expect(BrandConfig.brandName, isNotEmpty);
      expect(BrandConfig.authScheme, isNotEmpty);
      expect(BrandConfig.contentScheme, isNotEmpty);
      expect(BrandConfig.fontFamily, isNotEmpty);
      expect(BrandConfig.logoAsset, isNotEmpty);
      expect(BrandConfig.notificationChannelId, isNotEmpty);
    });
  });
}
