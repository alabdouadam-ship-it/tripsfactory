/// User-facing exception that does not leak technical details.
/// Use [userMessage] for display; [debugInfo] is for logs only.
/// When [messageKey] is set, the UI should resolve it via localization.
class TripShipException implements Exception {
  final String userMessage;
  final String? messageKey;
  final Object? _debugInfo;

  TripShipException(this.userMessage, [Object? debugInfo])
    : messageKey = null,
      _debugInfo = debugInfo;

  /// Creates exception with a localization key. [userMessage] is fallback.
  TripShipException.withKey(this.messageKey, this.userMessage, [Object? debugInfo])
    : _debugInfo = debugInfo;

  /// Use only for logging/debugging, never show to users.
  Object? get debugInfo => _debugInfo;

  @override
  String toString() => userMessage;

  /// Utility to wrap generic errors or Supabase errors into a TripShipException.
  static TripShipException fromObject(Object error) {
    if (error is TripShipException) return error;
    return TripShipException(error.toString(), error);
  }
}
