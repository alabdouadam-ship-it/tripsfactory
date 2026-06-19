import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  /// Checks if the device is connected to a network (WiFi or Mobile Data).
  ///
  /// NOTE: This does not guarantee actual internet access (e.g., connected to
  /// a router with no internet). For critical operations, consider a real
  /// reachability check via [InternetAddress.lookup].
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile,
    );
  }
}
