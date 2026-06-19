import 'package:tripship/core/config/brand_config.dart';
import 'package:tripship/core/config/domain_config.dart';

class AppConstants {
  static const String baseUrl = BrandConfig.webBaseUrl;
  static const String tripPath = '/trip';
  static const String shipmentPath = '/shipment';

  static String get tripBaseUrl => '$baseUrl$tripPath';
  static String get shipmentBaseUrl => '$baseUrl$shipmentPath';

  // Legal Links
  static String privacyPolicyUrl(String lang) =>
      '$baseUrl/privacy-policy-$lang.html';
  static String termsOfServiceUrl(String lang) =>
      '$baseUrl/terms-of-service-$lang.html';

  // Auth Constants
  static const String authCallbackReset = BrandConfig.authCallbackReset;
  static const String authCallbackLogin = BrandConfig.authCallbackLogin;
  static const String rpcCheckUserExists = 'check_user_exists';

  // Booking Roles
  static const String roleSender = DomainConfig.roleSender;
  static const String roleTraveler = DomainConfig.roleTraveler;
  static const String roleClient = DomainConfig.roleClient;
}
