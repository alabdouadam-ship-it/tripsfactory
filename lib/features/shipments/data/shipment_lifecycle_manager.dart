import 'dart:async';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/providers/app_localizations_provider.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/utils/logger.dart';

final shipmentLifecycleManagerProvider = Provider(
  (ref) => ShipmentLifecycleManager(ref),
);

/// Manages the shipment tracking lifecycle directly overriding restrictive RPCs.
class ShipmentLifecycleManager {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Ref _ref;

  ShipmentLifecycleManager(this._ref);

  Future<void> _notify({
    required String shipmentId,
    required String userId,
    required String title,
    required String body,
    required String recipientRole,
    required Map<String, dynamic> baseData,
  }) async {
    await _ref
        .read(notificationServiceProvider)
        .sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          data: baseData,
          recipientRole: recipientRole,
        );
  }

  /// Returns {driver_id, offer_id} for the accepted offer on a shipment —
  /// replaces the old separate _getDriverIdForShipment + _getOfferIdForShipment
  /// that each fired an identical query. Now a single round-trip.
  Future<({String? driverId, String? offerId})> _getAcceptedOfferInfo(
    String shipmentId,
  ) async {
    try {
      final rows = await _supabase
          .from('offers')
          .select('id, driver_id')
          .eq('shipment_id', shipmentId)
          .eq('status', 'accepted')
          .limit(1);
      if ((rows as List).isNotEmpty) {
        return (
          driverId: rows.first['driver_id'] as String?,
          offerId: rows.first['id'] as String?,
        );
      }
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentLifecycleManager',
        'Error getting accepted offer info',
        e,
        st,
      );
    }
    return (driverId: null, offerId: null);
  }

  Future<String?> _getSenderId(String shipmentId) async {
    try {
      final row = await _supabase
          .from('shipments')
          .select('sender_id')
          .eq('id', shipmentId)
          .maybeSingle();
      return row?['sender_id'] as String?;
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentLifecycleManager',
        'Error getting sender id',
        e,
        st,
      );
      return null;
    }
  }

  // ─── Handover Process ─────────────────────────────────────────────

  // Sender says: "I gave the goods"
  Future<void> markGoodsHandedOver(String shipmentId) async {
    // sender_id comes back from the shipment SELECT inside _updateHandshake
    await _updateHandshake(
      shipmentId: shipmentId,
      fieldName: 'goods_handed_by_sender_at',
    );
    final (:driverId, :offerId) = await _getAcceptedOfferInfo(shipmentId);
    if (driverId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: driverId,
          title: l10n.notifSenderHandedGoods,
          body: l10n.notifConfirmReceipt,
          baseData: {
            'type': 'shipment_goods_handed',
            'shipment_id': shipmentId,
            // ignore: use_null_aware_elements
            if (offerId != null) 'offer_id': offerId,
          },
          recipientRole: 'traveler',
        ),
      );
    }
  }

  // Driver says: "I received the goods" (Does NOT need User confirmation)
  Future<void> confirmGoodsReceived(String shipmentId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final shipment = await _supabase
        .from('shipments')
        .select('goods_handed_by_sender_at')
        .eq('id', shipmentId)
        .single();

    final updates = <String, dynamic>{};
    if (shipment['goods_handed_by_sender_at'] == null) {
      updates['goods_handed_by_sender_at'] = now;
    }

    final senderId = await _updateHandshake(
      shipmentId: shipmentId,
      fieldName: 'goods_received_by_driver_at',
      newStatus: ShipmentStatus.inTransit,
      additionalUpdates: updates,
    );

    if (senderId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: senderId,
          title: l10n.notifGoodsReceived,
          body: l10n.notifGoodsInTransit,
          baseData: {
            'type': 'shipment_goods_received',
            'shipment_id': shipmentId,
          },
          recipientRole: 'sender',
        ),
      );
    }
  }

  // ─── Delivery Process ─────────────────────────────────────────────

  // Mark as Delivered with OTP -> Instant Confirmation
  // The code is verified server-side; clients can no longer read it.
  Future<void> markGoodsDeliveredWithCode(
    String shipmentId,
    String code,
  ) async {
    final result = await _supabase.rpc(
      'verify_delivery_and_complete_shipment',
      params: {'p_shipment_id': shipmentId, 'p_code': code},
    );

    switch (result as String?) {
      case 'ok':
        break;
      case 'code_locked':
        throw TripShipException.withKey(
          'delivery_code_locked',
          'Too many wrong attempts. Ask the sender to confirm manually.',
        );
      default:
        throw TripShipException.withKey('invalid_code', 'Invalid delivery code');
    }

    final senderId = await _getSenderId(shipmentId);

    if (senderId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: senderId,
          title: l10n.notifDeliveredVerified,
          body: l10n.notifDeliveredVerifiedBody,
          baseData: {
            'type': 'shipment_completed_otp',
            'shipment_id': shipmentId,
          },
          recipientRole: 'sender',
        ),
      );
    }
  }

  // Mark as Delivered without OTP -> Requires Sender Confirmation
  Future<void> markGoodsDelivered(String shipmentId) async {
    final senderId = await _updateHandshake(
      shipmentId: shipmentId,
      fieldName: 'goods_delivered_by_driver_at',
      newStatus: ShipmentStatus.delivered,
    );

    if (senderId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: senderId,
          title: l10n.notifTravelerDelivered,
          body: l10n.notifConfirmReceipt,
          baseData: {
            'type': 'shipment_goods_delivered',
            'shipment_id': shipmentId,
          },
          recipientRole: 'sender',
        ),
      );
    }
  }

  // Client confirms receipt manually (if no OTP used)
  Future<void> confirmGoodsReceivedByClient(String shipmentId) async {
    final (:driverId, :offerId) = await _getAcceptedOfferInfo(shipmentId);
    await _updateHandshake(
      shipmentId: shipmentId,
      fieldName: 'goods_received_by_client_at',
      newStatus: ShipmentStatus.completed,
    );
    // NOTE: _updateHandshake already calls _completeAcceptedOffer when
    // newStatus == completed. No explicit call needed here.

    if (driverId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: driverId,
          title: l10n.notifClientConfirmedReceipt,
          body: l10n.notifDeliveryCompleted,
          baseData: {
            'type': 'shipment_completed',
            'shipment_id': shipmentId,
            // ignore: use_null_aware_elements
            if (offerId != null) 'offer_id': offerId,
          },
          recipientRole: 'traveler',
        ),
      );
    }
  }

  // ─── Payment Process ──────────────────────────────────────────────

  Future<void> markPaymentSent(String shipmentId) async {
    await _updateHandshake(
      shipmentId: shipmentId,
      fieldName: 'payment_marked_by_sender_at',
    );
    final (:driverId, :offerId) = await _getAcceptedOfferInfo(shipmentId);
    if (driverId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: driverId,
          title: l10n.notifPaymentMarked,
          body: l10n.notifConfirmPayment,
          baseData: {
            'type': 'shipment_payment_marked',
            'shipment_id': shipmentId,
            // ignore: use_null_aware_elements
            if (offerId != null) 'offer_id': offerId,
          },
          recipientRole: 'traveler',
        ),
      );
    }
  }

  Future<void> confirmPaymentReceived(String shipmentId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final shipment = await _supabase
        .from('shipments')
        .select('payment_marked_by_sender_at, sender_id')
        .eq('id', shipmentId)
        .single();

    final updates = <String, dynamic>{};
    if (shipment['payment_marked_by_sender_at'] == null) {
      updates['payment_marked_by_sender_at'] = now;
    }

    final senderId =
        await _updateHandshake(
          shipmentId: shipmentId,
          fieldName: 'payment_confirmed_by_driver_at',
          additionalUpdates: updates,
        ) ??
        shipment['sender_id'] as String?;

    if (senderId != null) {
      final l10n = _ref.read(appLocalizationsProvider);
      unawaited(
        _notify(
          shipmentId: shipmentId,
          userId: senderId,
          title: l10n.notifPaymentConfirmed,
          body: l10n.notifPaymentConfirmedBody,
          baseData: {
            'type': 'shipment_payment_confirmed',
            'shipment_id': shipmentId,
          },
          recipientRole: 'sender',
        ),
      );
    }
  }

  // ─── Core Updates ──────────────────────────────────────────

  /// Core lifecycle update. Returns the shipment's [sender_id] so callers can
  /// send sender notifications without an additional DB round-trip.
  Future<String?> _updateHandshake({
    required String shipmentId,
    required String fieldName,
    ShipmentStatus? newStatus,
    Map<String, dynamic>? additionalUpdates,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final shipment = await _supabase
        .from('shipments')
        .select('status, sender_id, $fieldName') // also fetch sender_id here
        .eq('id', shipmentId)
        .maybeSingle();

    if (shipment == null) {
      StructuredLogger.error(
        'ShipmentLifecycleManager',
        'Lifecycle Select ERROR: Shipment not found or restricted for $shipmentId',
      );
      throw TripShipException.withKey(
        'failed_load_shipment_details',
        'Could not access shipment details. Please check your permissions.',
      );
    }

    final senderId = shipment['sender_id'] as String?;

    if (shipment[fieldName] != null) return senderId; // Idempotency check

    final currentStatus = ShipmentStatus.fromString(shipment['status']);
    if (currentStatus == ShipmentStatus.completed ||
        currentStatus == ShipmentStatus.cancelled) {
      return senderId;
    }

    if (newStatus != null && !currentStatus.canTransitionTo(newStatus)) {
      throw TripShipException.withKey(
        'illegal_transition',
        'Cannot transition from ${currentStatus.toStringValue()} to ${newStatus.toStringValue()}.',
      );
    }

    final updates = {fieldName: now, ...?additionalUpdates};
    if (newStatus != null) {
      updates['status'] = newStatus.toStringValue();
    }

    final response = await _supabase
        .from('shipments')
        .update(updates)
        .eq('id', shipmentId)
        .select('id')
        .maybeSingle();

    if (response == null) {
      StructuredLogger.error(
        'ShipmentLifecycleManager',
        'Lifecycle Update ERROR: RLS or Row not found for $shipmentId',
      );
      throw TripShipException.withKey(
        'update_failed',
        'Failed to verify action. Check network or permissions.',
      );
    }

    // Auto-complete accepted offer if shipment is completed
    if (newStatus == ShipmentStatus.completed) {
      await _completeAcceptedOffer(shipmentId);
    }

    StructuredLogger.info(
      'ShipmentLifecycleManager',
      'Lifecycle Update SUCCESS: $fieldName for $shipmentId',
    );
    return senderId;
  }

  Future<void> _completeAcceptedOffer(String shipmentId) async {
    try {
      await _supabase
          .from('offers')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('shipment_id', shipmentId)
          .eq('status', 'accepted');
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentLifecycleManager',
        'Error completing offer',
        e,
        st,
      );
    }
  }
}
