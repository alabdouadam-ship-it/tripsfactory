import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/utils/error_utils.dart';

void main() {
  group('getUserFriendlyMessage', () {
    test('returns userMessage for TripShipException', () {
      const msg = 'Cannot cancel: payment confirmed';
      expect(getUserFriendlyMessage(TripShipException(msg)), msg);
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
