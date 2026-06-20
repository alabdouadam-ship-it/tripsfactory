import 'package:tripsfactory/core/services/notification_service.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'booking_notification_enrichment_service.dart';

/// Sends enriched notifications (fire-and-forget dispatch after enrichment).
class BookingNotificationDispatchService {
  BookingNotificationDispatchService(this._ref, this._enrichment);

  final Ref _ref;
  final BookingNotificationEnrichmentService _enrichment;

  Future<void> notifyUser({
    required String bookingId,
    required String userId,
    required String title,
    required String body,
    required String recipientRole,
    required Map<String, dynamic> baseData,
  }) async {
    Map<String, dynamic> payload = Map<String, dynamic>.from(baseData);
    try {
      payload = await _enrichment.enrichNotificationDataForBooking(
        bookingId,
        baseData,
      );
    } catch (e, stack) {
      StructuredLogger.error(
        'BookingNotificationDispatchService',
        'Notification enrichment failed; sending base payload',
        e,
        stack,
      );
    }

    try {
      await _ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: userId,
            title: title,
            body: body,
            data: payload,
            recipientRole: recipientRole,
          );
    } catch (e, stack) {
      StructuredLogger.error(
        'BookingNotificationDispatchService',
        'Notification dispatch failed (non-blocking)',
        e,
        stack,
      );
    }
  }

  Future<Map<String, dynamic>> enrichOnly(
    String bookingId,
    Map<String, dynamic> baseData,
  ) {
    return _enrichment.enrichNotificationDataForBooking(bookingId, baseData);
  }

  void sendRaw({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String recipientRole,
  }) {
    _ref
        .read(notificationServiceProvider)
        .sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          data: data,
          recipientRole: recipientRole,
        );
  }
}
