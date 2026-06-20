import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

/// Validates cancel preconditions (mirrors legacy `cancelBooking` guards).
class BookingCancellationGuard {
  const BookingCancellationGuard();

  void validate({
    required Map<String, dynamic> bookingRow,
    required bool isDriver,
  }) {
    final currentStatus = BookingStatus.fromString(
      bookingRow['status'] as String?,
    );

    if (currentStatus == BookingStatus.inTransit ||
        currentStatus == BookingStatus.delivered ||
        currentStatus == BookingStatus.completed) {
      throw TripsFactoryException.withKey(
        'cannot_cancel_active_booking',
        'Cannot cancel: this booking is already in progress or completed.',
      );
    }

    if (!isDriver && bookingRow['goods_received_by_traveler_at'] != null) {
      throw TripsFactoryException.withKey(
        'cannot_cancel_goods_handed_over',
        'Cannot cancel: goods have already been handed over to the driver.',
      );
    }

    if (bookingRow['payment_confirmed_by_traveler_at'] != null) {
      throw TripsFactoryException.withKey(
        'cannot_cancel_payment_confirmed',
        'Cannot cancel: payment has already been confirmed.',
      );
    }
  }
}
