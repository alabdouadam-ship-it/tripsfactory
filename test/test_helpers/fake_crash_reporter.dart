/// Captures crash/fatal events for tests. Use to assert unhandled errors are reported
/// and handled expected errors are not.
class FakeCrashReporter {
  final List<FakeCrashEvent> events = [];

  void reportFatal(
    String context,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    events.add(
      FakeCrashEvent(
        context: context,
        message: message,
        error: error?.toString(),
        hasStackTrace: stackTrace != null,
      ),
    );
  }

  void clear() => events.clear();
}

class FakeCrashEvent {
  final String context;
  final String message;
  final String? error;
  final bool hasStackTrace;

  FakeCrashEvent({
    required this.context,
    required this.message,
    this.error,
    this.hasStackTrace = false,
  });
}
