import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';

void main() {
  group('TripShipException', () {
    test('toString returns userMessage', () {
      const msg = 'Something went wrong';
      expect(TripShipException(msg).toString(), msg);
    });

    test('userMessage is accessible', () {
      const msg = 'Failed to load';
      expect(TripShipException(msg).userMessage, msg);
    });

    test('debugInfo is stored but not exposed in toString', () {
      final e = TripShipException('User error', 'internal: 500');
      expect(e.toString(), 'User error');
      expect(e.debugInfo, 'internal: 500');
    });
  });
}
