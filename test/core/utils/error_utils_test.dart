import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/utils/error_utils.dart';

void main() {
  group('getUserFriendlyMessage', () {
    test('returns userMessage for TripsFactoryException', () {
      const msg = 'Cannot cancel: payment confirmed';
      expect(getUserFriendlyMessage(TripsFactoryException(msg)), msg);
    });

    test('returns fallback for generic Exception', () {
      const fallback = 'Something went wrong';
      expect(getUserFriendlyMessage(Exception('internal'), fallback), fallback);
    });

    test('returns fallback for non-Exception errors', () {
      const fallback = 'Try again';
      expect(getUserFriendlyMessage('random string', fallback), fallback);
    });
  });
}
