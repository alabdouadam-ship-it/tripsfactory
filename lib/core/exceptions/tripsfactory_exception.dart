/// User-facing exception that does not leak technical details.
/// Use [userMessage] for display; [debugInfo] is for logs only.
/// When [messageKey] is set, the UI should resolve it via localization.
class TripsFactoryException implements Exception {
  final String userMessage;
  final String? messageKey;
  final Object? _debugInfo;

  TripsFactoryException(this.userMessage, [Object? debugInfo])
    : messageKey = null,
      _debugInfo = debugInfo;

  /// Creates exception with a localization key. [userMessage] is fallback.
  TripsFactoryException.withKey(this.messageKey, this.userMessage, [Object? debugInfo])
    : _debugInfo = debugInfo;

  /// Use only for logging/debugging, never show to users.
  Object? get debugInfo => _debugInfo;

  @override
  String toString() => userMessage;

  /// Utility to wrap generic errors or Supabase errors into a TripsFactoryException.
  static TripsFactoryException fromObject(Object error) {
    if (error is TripsFactoryException) return error;
    return TripsFactoryException(error.toString(), error);
  }
}
