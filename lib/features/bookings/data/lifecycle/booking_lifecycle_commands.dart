import 'dart:async';
import 'dart:io';

import 'package:tripsfactory/core/config/app_constants.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/providers/app_localizations_provider.dart';
import 'package:tripsfactory/core/services/notification_service.dart';
import 'package:tripsfactory/core/utils/logger.dart';

import 'booking_lifecycle_context.dart';

/// Accept booking (driver accepts sender request).
class AcceptBookingCommand {
  AcceptBookingCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('traveler_id, requester_id, trip_id')
        .eq('id', bookingId)
        .single();

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      timelineEvent: 'booking_accepted',
      newStatus: BookingStatus.accepted,
    );

    if (booking['trip_id'] != null) {
      await _ctx.tripSync.updateTripStatus(
        booking['trip_id'] as String,
        TripStatus.booked,
      );
    }

    final currentUserId = _ctx.supabase.auth.currentUser!.id;
    final travelerId = booking['traveler_id'] as String?;
    final requesterId = booking['requester_id'] as String?;
    final travelerAccepted = currentUserId == travelerId;
    final notifyUserId = travelerAccepted
        ? (requesterId ?? travelerId!)
        : (travelerId ?? currentUserId);
    final l10n = _ctx.ref.read(appLocalizationsProvider);
    final notificationData = await _ctx.enrichment.enrichNotificationDataForBooking(
      bookingId,
      {'type': 'booking_accepted', 'booking_id': bookingId},
    );

    unawaited(_ctx.ref
        .read(notificationServiceProvider)
        .sendNotificationToUser(
          userId: notifyUserId,
          title: l10n.notifBookingApproved,
          body: l10n.notifBookingApprovedBody,
          data: notificationData,
          recipientRole: travelerAccepted
              ? AppConstants.roleSender
              : AppConstants.roleTraveler,
        ));

    if (travelerId != null) {
      unawaited(_ctx.ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: travelerId,
            title: l10n.warningCheckGoodsTitle,
            body: l10n.warningCheckGoodsBody,
            data: notificationData,
            recipientRole: AppConstants.roleTraveler,
          ));
    }

    if (requesterId != null) {
      unawaited(_ctx.ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: requesterId,
            title: l10n.warningCheckTravelerTitle,
            body: l10n.warningCheckTravelerBody,
            data: notificationData,
            recipientRole: AppConstants.roleSender,
          ));
    }
  }
}

class RejectBookingCommand {
  RejectBookingCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('traveler_id, requester_id, trip_id')
        .eq('id', bookingId)
        .single();

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      timelineEvent: 'booking_rejected',
      newStatus: BookingStatus.rejected,
    );

    if (booking['trip_id'] != null) {
      await _ctx.tripSync.checkAndCompleteTrip(booking['trip_id'] as String);
    }

    final currentUserId = _ctx.supabase.auth.currentUser!.id;
    final travelerId = booking['traveler_id'] as String?;
    final requesterId = booking['requester_id'] as String?;

    final travelerRejected = currentUserId == travelerId;
    final notifyUserId = travelerRejected
        ? (requesterId ?? travelerId!)
        : (travelerId ?? currentUserId);

    final recipientRole = travelerRejected
        ? AppConstants.roleSender
        : AppConstants.roleTraveler;

    final l10n = _ctx.ref.read(appLocalizationsProvider);
    await _ctx.notifications.notifyUser(
      bookingId: bookingId,
      userId: notifyUserId,
      title: l10n.notifBookingDeclined,
      body: l10n.notifBookingDeclinedBody,
      recipientRole: recipientRole,
      baseData: {'type': 'booking_rejected', 'booking_id': bookingId},
    );
  }
}

class MarkGoodsHandedOverCommand {
  MarkGoodsHandedOverCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('traveler_id')
        .eq('id', bookingId)
        .single();
    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      fieldName: 'goods_handed_by_sender_at',
      timelineEvent: 'goods_handed_by_sender',
    );
    final l10n = _ctx.ref.read(appLocalizationsProvider);
    await _ctx.notifications.notifyUser(
      bookingId: bookingId,
      userId: booking['traveler_id'] as String,
      title: l10n.notifSenderHandedGoods,
      body: l10n.notifConfirmReceipt,
      recipientRole: AppConstants.roleTraveler,
      baseData: {'type': 'goods_handed', 'booking_id': bookingId},
    );
  }
}

class ConfirmGoodsReceivedCommand {
  ConfirmGoodsReceivedCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId, {File? pickupPhoto}) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final booking = await _ctx.supabase
        .from('bookings')
        .select('goods_handed_by_sender_at')
        .eq('id', bookingId)
        .single();
    final updates = <String, dynamic>{};

    if (booking['goods_handed_by_sender_at'] == null) {
      updates['goods_handed_by_sender_at'] = now;
    }

    if (pickupPhoto != null) {
      final url = await _ctx.photos.uploadDeliveryPhoto(
        pickupPhoto,
        bookingId,
        'pickup',
      );
      if (url != null) {
        updates['pickup_photo_url'] = url;
      }
    }

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      fieldName: 'goods_received_by_traveler_at',
      timelineEvent: 'goods_received_by_traveler',
      newStatus: BookingStatus.inTransit,
      additionalUpdates: updates,
    );
    final senderId = await _ctx.enrichment.getSenderIdForBooking(bookingId);
    if (senderId != null) {
      final l10n = _ctx.ref.read(appLocalizationsProvider);
      await _ctx.notifications.notifyUser(
        bookingId: bookingId,
        userId: senderId,
        title: l10n.notifGoodsReceived,
        body: l10n.notifConfirmReceipt,
        recipientRole: AppConstants.roleSender,
        baseData: {'type': 'goods_received', 'booking_id': bookingId},
      );
    }
  }
}

class MarkGoodsDeliveredWithCodeCommand {
  MarkGoodsDeliveredWithCodeCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  }) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('trip_id')
        .eq('id', bookingId)
        .single();

    String? photoUrl;
    if (deliveryPhoto != null) {
      photoUrl = await _ctx.photos.uploadDeliveryPhoto(
        deliveryPhoto,
        bookingId,
        'delivery',
      );
    }

    // Server-side verification + atomic completion (timeline included);
    // clients can no longer read the code.
    final result = await _ctx.supabase.rpc(
      'verify_delivery_and_complete_booking',
      params: {
        'p_booking_id': bookingId,
        'p_code': code,
        'p_delivery_photo_url': photoUrl,
      },
    );

    switch (result as String?) {
      case 'ok':
        break;
      case 'code_locked':
        throw TripsFactoryException.withKey(
          'delivery_code_locked',
          'Too many wrong attempts. Ask the sender to confirm manually.',
        );
      default:
        throw TripsFactoryException.withKey('invalid_otp', 'Invalid delivery code');
    }

    if (booking['trip_id'] != null) {
      await _ctx.tripSync.autoMarkTripFullIfNeeded(booking['trip_id'] as String);
      await _ctx.tripSync.checkAndCompleteTrip(booking['trip_id'] as String);
    }

    final senderId = await _ctx.enrichment.getSenderIdForBooking(bookingId);
    if (senderId != null) {
      final l10n = _ctx.ref.read(appLocalizationsProvider);
      await _ctx.notifications.notifyUser(
        bookingId: bookingId,
        userId: senderId,
        title: l10n.notifDeliveredVerified,
        body: l10n.notifDeliveredVerifiedBody,
        recipientRole: AppConstants.roleSender,
        baseData: {'type': 'goods_delivered_otp', 'booking_id': bookingId},
      );
    }
  }
}

class MarkGoodsDeliveredCommand {
  MarkGoodsDeliveredCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId, {File? deliveryPhoto}) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('trip_id')
        .eq('id', bookingId)
        .single();

    final updates = <String, dynamic>{};
    if (deliveryPhoto != null) {
      final url = await _ctx.photos.uploadDeliveryPhoto(
        deliveryPhoto,
        bookingId,
        'delivery',
      );
      if (url != null) {
        updates['delivery_photo_url'] = url;
      }
    }

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      timelineEvent: 'goods_delivered_by_traveler',
      fieldName: 'goods_delivered_by_traveler_at',
      newStatus: BookingStatus.delivered,
      additionalUpdates: updates.isNotEmpty ? updates : null,
    );

    if (booking['trip_id'] != null) {
      await _ctx.tripSync.autoMarkTripFullIfNeeded(booking['trip_id'] as String);
    }

    final senderId = await _ctx.enrichment.getSenderIdForBooking(bookingId);
    if (senderId != null) {
      final l10n = _ctx.ref.read(appLocalizationsProvider);
      await _ctx.notifications.notifyUser(
        bookingId: bookingId,
        userId: senderId,
        title: l10n.notifTravelerDelivered,
        body: l10n.notifConfirmReceipt,
        recipientRole: AppConstants.roleSender,
        baseData: {'type': 'goods_delivered', 'booking_id': bookingId},
      );
    }
  }
}

class ConfirmGoodsReceivedByClientCommand {
  ConfirmGoodsReceivedByClientCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('trip_id, traveler_id')
        .eq('id', bookingId)
        .single();

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      fieldName: 'goods_received_by_client_at',
      timelineEvent: 'goods_received_by_client',
      newStatus: BookingStatus.completed,
    );

    if (booking['trip_id'] != null) {
      await _ctx.tripSync.autoMarkTripFullIfNeeded(booking['trip_id'] as String);
      await _ctx.tripSync.checkAndCompleteTrip(booking['trip_id'] as String);
    }

    final travelerId = booking['traveler_id'];
    if (travelerId != null) {
      final l10n = _ctx.ref.read(appLocalizationsProvider);
      await _ctx.notifications.notifyUser(
        bookingId: bookingId,
        userId: travelerId as String,
        title: l10n.notifGoodsReceived,
        body: l10n.notifClientConfirmedReceiptBody,
        recipientRole: AppConstants.roleTraveler,
        baseData: {'type': 'delivery_completed', 'booking_id': bookingId},
      );
    }
  }
}

class MarkPaymentSentCommand {
  MarkPaymentSentCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select('traveler_id')
        .eq('id', bookingId)
        .single();
    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      fieldName: 'payment_marked_by_sender_at',
      timelineEvent: 'payment_marked_by_sender',
    );
    final l10n = _ctx.ref.read(appLocalizationsProvider);
    await _ctx.notifications.notifyUser(
      bookingId: bookingId,
      userId: booking['traveler_id'] as String,
      title: l10n.notifPaymentMarked,
      body: l10n.notifConfirmPayment,
      recipientRole: AppConstants.roleTraveler,
      baseData: {'type': 'payment_marked', 'booking_id': bookingId},
    );
  }
}

class ConfirmPaymentReceivedCommand {
  ConfirmPaymentReceivedCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(String bookingId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final booking = await _ctx.supabase
        .from('bookings')
        .select('payment_marked_by_sender_at')
        .eq('id', bookingId)
        .single();
    final updates = <String, dynamic>{};

    if (booking['payment_marked_by_sender_at'] == null) {
      updates['payment_marked_by_sender_at'] = now;
    }

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      fieldName: 'payment_confirmed_by_traveler_at',
      timelineEvent: 'payment_confirmed_by_traveler',
      additionalUpdates: updates,
    );
    final senderId = await _ctx.enrichment.getSenderIdForBooking(bookingId);
    if (senderId != null) {
      final l10n = _ctx.ref.read(appLocalizationsProvider);
      await _ctx.notifications.notifyUser(
        bookingId: bookingId,
        userId: senderId,
        title: l10n.notifPaymentConfirmed,
        body: l10n.notifPaymentConfirmedBody,
        recipientRole: AppConstants.roleSender,
        baseData: {'type': 'payment_confirmed', 'booking_id': bookingId},
      );
    }
  }
}

class CancelBookingCommand {
  CancelBookingCommand(this._ctx);
  final BookingLifecycleContext _ctx;

  Future<void> execute(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) async {
    final booking = await _ctx.supabase
        .from('bookings')
        .select(
          'goods_received_by_traveler_at, payment_confirmed_by_traveler_at, trip_id, traveler_id, requester_id, status',
        )
        .eq('id', bookingId)
        .single();

    _ctx.cancelGuard.validate(bookingRow: booking, isDriver: isDriver);

    await _ctx.handshake.applyHandshake(
      bookingId: bookingId,
      timelineEvent: isDriver
          ? 'booking_cancelled_by_driver'
          : 'booking_cancelled_by_user',
      newStatus: BookingStatus.cancelled,
      additionalUpdates: {'message': 'Reason: $reason'},
    );

    try {
      final currentUserId = _ctx.supabase.auth.currentUser!.id;
      final travelerId = booking['traveler_id'] as String?;
      final requesterId = booking['requester_id'] as String?;
      final senderId =
          requesterId ?? await _ctx.enrichment.getSenderIdForBooking(bookingId);

      final notifyUserId = isDriver ? senderId : travelerId;
      if (notifyUserId != null && notifyUserId != currentUserId) {
        final l10n = _ctx.ref.read(appLocalizationsProvider);
        await _ctx.notifications.notifyUser(
          bookingId: bookingId,
          userId: notifyUserId,
          title: l10n.notifBookingCancelled,
          body: l10n.notifBookingCancelledBody,
          recipientRole: isDriver
              ? AppConstants.roleSender
              : AppConstants.roleTraveler,
          baseData: {'type': 'booking_cancelled', 'booking_id': bookingId},
        );
      }
    } catch (e) {
      StructuredLogger.error(
        'CancelBookingCommand',
        'Cancel notification failed',
        e,
      );
    }

    final tripId = booking['trip_id'];
    if (tripId != null) {
      await _ctx.tripSync.checkAndCompleteTrip(tripId as String);
    }
  }
}
