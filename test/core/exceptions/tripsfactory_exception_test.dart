import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

void main() {
  group('TripsFactoryException', () {
    test('toString returns userMessage', () {
      const msg = 'Something went wrong';
      expect(TripsFactoryException(msg).toString(), msg);
    });

    test('userMessage is accessible', () {
      const msg = 'Failed to load';
      expect(TripsFactoryException(msg).userMessage, msg);
    });

    test('debugInfo is stored but not exposed in toString', () {
      final e = TripsFactoryException('User error', 'internal: 500');
      expect(e.toString(), 'User error');
      expect(e.debugInfo, 'internal: 500');
    });
  });
}
