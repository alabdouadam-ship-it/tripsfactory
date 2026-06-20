import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/core/enums/app_enums.dart';

/// Factory for test bookings in each pipeline state (requester vs traveler view is same model).
class BookingFixture {
  static final _base = Booking(
    id: 'fixture-booking-1',
    driverId: 'driver-1',
    price: 100,
    status: BookingStatus.pending,
    createdAt: DateTime(2025, 1, 15, 10, 0),
  );

  static Booking pending() => _base;

  static Booking accepted() => _base.copyWith(status: BookingStatus.accepted);

  static Booking paymentPending() => _base.copyWith(
    status: BookingStatus.accepted,
    goodsHandedBySenderAt: DateTime(2025, 1, 15, 11, 0),
    goodsReceivedByDriverAt: DateTime(2025, 1, 15, 11, 5),
  );

  static Booking paymentConfirmed() => _base.copyWith(
    status: BookingStatus.inTransit,
    goodsHandedBySenderAt: DateTime(2025, 1, 15, 11, 0),
    goodsReceivedByDriverAt: DateTime(2025, 1, 15, 11, 5),
    paymentMarkedBySenderAt: DateTime(2025, 1, 15, 12, 0),
    paymentConfirmedByDriverAt: DateTime(2025, 1, 15, 12, 5),
  );

  static Booking inTransit() => _base.copyWith(
    status: BookingStatus.inTransit,
    goodsHandedBySenderAt: DateTime(2025, 1, 15, 11, 0),
    goodsReceivedByDriverAt: DateTime(2025, 1, 15, 11, 5),
    paymentMarkedBySenderAt: DateTime(2025, 1, 15, 12, 0),
    paymentConfirmedByDriverAt: DateTime(2025, 1, 15, 12, 5),
  );

  static Booking delivered() => _base.copyWith(
    status: BookingStatus.delivered,
    goodsHandedBySenderAt: DateTime(2025, 1, 15, 11, 0),
    goodsReceivedByDriverAt: DateTime(2025, 1, 15, 11, 5),
    paymentMarkedBySenderAt: DateTime(2025, 1, 15, 12, 0),
    paymentConfirmedByDriverAt: DateTime(2025, 1, 15, 12, 5),
    goodsDeliveredByDriverAt: DateTime(2025, 1, 15, 14, 0),
  );

  static Booking completed() => _base.copyWith(
    status: BookingStatus.completed,
    goodsHandedBySenderAt: DateTime(2025, 1, 15, 11, 0),
    goodsReceivedByDriverAt: DateTime(2025, 1, 15, 11, 5),
    paymentMarkedBySenderAt: DateTime(2025, 1, 15, 12, 0),
    paymentConfirmedByDriverAt: DateTime(2025, 1, 15, 12, 5),
    goodsDeliveredByDriverAt: DateTime(2025, 1, 15, 14, 0),
    goodsReceivedByClientAt: DateTime(2025, 1, 15, 14, 10),
  );
}
