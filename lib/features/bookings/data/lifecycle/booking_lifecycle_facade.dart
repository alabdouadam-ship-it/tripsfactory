import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/enums/app_enums.dart';

import 'booking_lifecycle_commands.dart';
import 'booking_lifecycle_context.dart';

/// Orchestrates booking lifecycle commands; preserves legacy public API surface.
class BookingLifecycleFacade {
  BookingLifecycleFacade(Ref ref) : _ctx = BookingLifecycleContext(ref);

  final BookingLifecycleContext _ctx;

  Future<void> acceptBooking(String bookingId) =>
      AcceptBookingCommand(_ctx).execute(bookingId);

  Future<void> rejectBooking(String bookingId) =>
      RejectBookingCommand(_ctx).execute(bookingId);

  Future<void> markGoodsHandedOver(String bookingId) =>
      MarkGoodsHandedOverCommand(_ctx).execute(bookingId);

  Future<void> confirmGoodsReceived(String bookingId, {File? pickupPhoto}) =>
      ConfirmGoodsReceivedCommand(_ctx).execute(bookingId, pickupPhoto: pickupPhoto);

  Future<void> markGoodsDeliveredWithCode(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  }) =>
      MarkGoodsDeliveredWithCodeCommand(_ctx).execute(
        bookingId,
        code,
        deliveryPhoto: deliveryPhoto,
      );

  Future<void> markGoodsDelivered(String bookingId, {File? deliveryPhoto}) =>
      MarkGoodsDeliveredCommand(_ctx).execute(bookingId, deliveryPhoto: deliveryPhoto);

  Future<void> confirmGoodsReceivedByClient(String bookingId) =>
      ConfirmGoodsReceivedByClientCommand(_ctx).execute(bookingId);

  Future<void> markPaymentSent(String bookingId) =>
      MarkPaymentSentCommand(_ctx).execute(bookingId);

  Future<void> confirmPaymentReceived(String bookingId) =>
      ConfirmPaymentReceivedCommand(_ctx).execute(bookingId);

  Future<void> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) =>
      CancelBookingCommand(_ctx).execute(
        bookingId,
        isDriver: isDriver,
        reason: reason,
      );

  /// Called from [BookingService] for trip workflow updates.
  Future<void> updateTripStatus(String tripId, TripStatus newStatus) =>
      _ctx.tripSync.updateTripStatus(tripId, newStatus);
}
