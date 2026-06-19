// روابط المتاجر للتطبيق - سهلة التعديل
// Store links for the app - easy to change
//
// القيم الفعلية موجودة الآن في [BrandConfig] (نقطة العلامة التجارية الموحّدة).
// The actual values now live in [BrandConfig] (the single brand seam).
import 'package:tripship/core/config/brand_config.dart';

/// رابط التطبيق على Google Play
const String playStoreUrl = BrandConfig.playStoreUrl;

/// رابط التطبيق على App Store (iOS) - ضع الرابط عند النشر
const String appStoreUrl = BrandConfig.appStoreUrl;
