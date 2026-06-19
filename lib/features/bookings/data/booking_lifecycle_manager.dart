import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/enums/app_enums.dart';

import 'lifecycle/booking_lifecycle_facade.dart';

final bookingLifecycleManagerProvider = Provider(
  (ref) => BookingLifecycleManager(ref),
);

/// Thin entrypoint delegating to [BookingLifecycleFacade].
///
/// Keeps provider name and type stable for [BookingRepository] and [BookingService].
class BookingLifecycleManager {
  BookingLifecycleManager(Ref ref) : _facade = BookingLifecycleFacade(ref);

  final BookingLifecycleFacade _facade;

  Future<void> acceptBooking(String bookingId) =>
      _facade.acceptBooking(bookingId);

  Future<void> rejectBooking(String bookingId) =>
      _facade.rejectBooking(bookingId);

  Future<void> markGoodsHandedOver(String bookingId) =>
      _facade.markGoodsHandedOver(bookingId);

  Future<void> confirmGoodsReceived(String bookingId, {File? pickupPhoto}) =>
      _facade.confirmGoodsReceived(bookingId, pickupPhoto: pickupPhoto);

  Future<void> markGoodsDeliveredWithCode(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  }) =>
      _facade.markGoodsDeliveredWithCode(
        bookingId,
        code,
        deliveryPhoto: deliveryPhoto,
      );

  Future<void> markGoodsDelivered(String bookingId, {File? deliveryPhoto}) =>
      _facade.markGoodsDelivered(bookingId, deliveryPhoto: deliveryPhoto);

  Future<void> confirmGoodsReceivedByClient(String bookingId) =>
      _facade.confirmGoodsReceivedByClient(bookingId);

  Future<void> markPaymentSent(String bookingId) =>
      _facade.markPaymentSent(bookingId);

  Future<void> confirmPaymentReceived(String bookingId) =>
      _facade.confirmPaymentReceived(bookingId);

  Future<void> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) =>
      _facade.cancelBooking(
        bookingId,
        isDriver: isDriver,
        reason: reason,
      );

  Future<void> updateTripStatus(String tripId, TripStatus newStatus) =>
      _facade.updateTripStatus(tripId, newStatus);
}
