import 'dart:convert';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, fatal }

class StructuredLogger {
  static void log(
    LogLevel level,
    String context,
    String message, [
    Map<String, dynamic>? payload,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode && level == LogLevel.info) {
      return; // Skip info logs in production
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final levelStr = level.name.toUpperCase();

    String logString = '[$timestamp] [$levelStr] [$context] - $message';

    if (payload != null) {
      try {
        logString += ' | ${jsonEncode(payload)}';
      } catch (_) {
        logString += ' | { Error encoding payload }';
      }
    }

    if (error != null) {
      logString += '\nError: $error';
    }

    if (stackTrace != null) {
      logString += '\nStack: $stackTrace';
    }

    // In a real app, this would be sent to Sentry/Crashlytics/Datadog if level == error || fatal
    // For now, we print structured logs to the console
    debugPrint(logString);
  }

  static void info(
    String context,
    String message, [
    Map<String, dynamic>? payload,
  ]) {
    log(LogLevel.info, context, message, payload);
  }

  static void warning(
    String context,
    String message, [
    Map<String, dynamic>? payload,
  ]) {
    log(LogLevel.warning, context, message, payload);
  }

  static void error(
    String context,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? payload,
  ]) {
    log(LogLevel.error, context, message, payload, error, stackTrace);
  }

  static void fatal(
    String context,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? payload,
  ]) {
    log(LogLevel.fatal, context, message, payload, error, stackTrace);
    // Here we would normally trigger a crash report to a remote service.
  }
}
