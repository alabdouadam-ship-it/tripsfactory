import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import '../test_helpers/fake_crash_reporter.dart';

/// Structured logging: required fields present; fatal path exists. Crash reporter hook when used.
void main() {
  group('StructuredLogger', () {
    test('log produces output with level and context', () {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? msg, {int? wrapWidth}) {
        if (msg != null) logs.add(msg);
      };
      addTearDown(() => debugPrint = original);

      StructuredLogger.log(
        LogLevel.info,
        'TestContext',
        'Test message',
        {'bookingId': 'b1'},
      );

      expect(logs, isNotEmpty);
      expect(logs.any((s) => s.contains('TestContext')), true);
      expect(logs.any((s) => s.contains('INFO')), true);
      expect(logs.any((s) => s.contains('Test message')), true);
      expect(logs.any((s) => s.contains('bookingId')), true);
    });

    test('error log includes error and stack when provided', () {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? msg, {int? wrapWidth}) {
        if (msg != null) logs.add(msg);
      };
      addTearDown(() => debugPrint = original);

      StructuredLogger.error(
        'BookingService',
        'Accept failed',
        Exception('Network error'),
        StackTrace.current,
        {'bookingId': 'b2'},
      );

      expect(logs, isNotEmpty);
      expect(logs.any((s) => s.contains('ERROR')), true);
      expect(logs.any((s) => s.contains('BookingService')), true);
      expect(logs.any((s) => s.contains('Accept failed')), true);
      expect(logs.any((s) => s.contains('Network error')), true);
    });

    test('fatal log produces output (crash report hook would run in production)', () {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? msg, {int? wrapWidth}) {
        if (msg != null) logs.add(msg);
      };
      addTearDown(() => debugPrint = original);

      StructuredLogger.fatal(
        'ZonedGuarded',
        'Uncaught error',
        Exception('Fatal'),
        StackTrace.current,
      );

      expect(logs, isNotEmpty);
      expect(logs.any((s) => s.contains('FATAL')), true);
      expect(logs.any((s) => s.contains('ZonedGuarded')), true);
    });
  });

  group('FakeCrashReporter', () {
    test('captures reportFatal events', () {
      final reporter = FakeCrashReporter();
      reporter.reportFatal('Context', 'msg', Exception('e'), StackTrace.current);
      expect(reporter.events.length, 1);
      expect(reporter.events[0].context, 'Context');
      expect(reporter.events[0].message, 'msg');
      expect(reporter.events[0].hasStackTrace, true);
    });
  });
}
