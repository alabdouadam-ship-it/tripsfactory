import 'package:tripsfactory/core/utils/logger.dart';

/// Captures log calls for tests. Replace [StructuredLogger] output or use as callback.
class FakeLogger {
  final List<FakeLogEntry> entries = [];

  void log(
    LogLevel level,
    String context,
    String message, [
    Map<String, dynamic>? payload,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    entries.add(
      FakeLogEntry(
        level: level,
        context: context,
        message: message,
        payload: payload != null ? Map<String, dynamic>.from(payload) : null,
        error: error?.toString(),
        hasStackTrace: stackTrace != null,
      ),
    );
  }

  List<FakeLogEntry> get errors =>
      entries.where((e) => e.level == LogLevel.error).toList();
  List<FakeLogEntry> get fatals =>
      entries.where((e) => e.level == LogLevel.fatal).toList();
}

class FakeLogEntry {
  final LogLevel level;
  final String context;
  final String message;
  final Map<String, dynamic>? payload;
  final String? error;
  final bool hasStackTrace;

  FakeLogEntry({
    required this.level,
    required this.context,
    required this.message,
    this.payload,
    this.error,
    this.hasStackTrace = false,
  });
}
