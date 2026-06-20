import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/booking_cancellation_guard.dart';

void main() {
  const guard = BookingCancellationGuard();

  test('throws cannot_cancel_active_booking for in_transit', () {
    expect(
      () => guard.validate(
        bookingRow: {'status': 'in_transit'},
        isDriver: false,
      ),
      throwsA(
        predicate<TripsFactoryException>(
            (e) => e.messageKey == 'cannot_cancel_active_booking'),
      ),
    );
  });

  test('throws cannot_cancel_active_booking for delivered', () {
    expect(
      () => guard.validate(
        bookingRow: {'status': 'delivered'},
        isDriver: false,
      ),
      throwsA(
        predicate<TripsFactoryException>(
            (e) => e.messageKey == 'cannot_cancel_active_booking'),
      ),
    );
  });

  test('throws cannot_cancel_active_booking for completed', () {
    expect(
      () => guard.validate(
        bookingRow: {'status': 'completed'},
        isDriver: false,
      ),
      throwsA(
        predicate<TripsFactoryException>(
            (e) => e.messageKey == 'cannot_cancel_active_booking'),
      ),
    );
  });

  test('throws cannot_cancel_goods_handed_over for sender', () {
    expect(
      () => guard.validate(
        bookingRow: {
          'status': 'accepted',
          'goods_received_by_traveler_at': 'ts',
        },
        isDriver: false,
      ),
      throwsA(
        predicate<TripsFactoryException>(
            (e) => e.messageKey == 'cannot_cancel_goods_handed_over'),
      ),
    );
  });

  test('allows sender cancel when driver has goods but isDriver', () {
    expect(
      () => guard.validate(
        bookingRow: {
          'status': 'accepted',
          'goods_received_by_traveler_at': 'ts',
        },
        isDriver: true,
      ),
      returnsNormally,
    );
  });

  test('throws cannot_cancel_payment_confirmed', () {
    expect(
      () => guard.validate(
        bookingRow: {
          'status': 'accepted',
          'payment_confirmed_by_traveler_at': 'ts',
        },
        isDriver: true,
      ),
      throwsA(
        predicate<TripsFactoryException>(
            (e) => e.messageKey == 'cannot_cancel_payment_confirmed'),
      ),
    );
  });
}
