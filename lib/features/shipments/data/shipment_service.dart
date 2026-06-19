import 'dart:async';
// ignore_for_file: use_null_aware_elements
import 'package:tripship/core/utils/stream_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/shipments/data/shipment_alert_service.dart';
import 'package:tripship/features/shipments/data/shipment_lifecycle_manager.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/core/providers/app_localizations_provider.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/utils/logger.dart';

final shipmentServiceProvider = Provider<ShipmentService>((ref) {
  return ShipmentService(Supabase.instance.client, ref);
});

class ShipmentService {
  final SupabaseClient _client;
  final Ref _ref;

  ShipmentService(this._client, this._ref);

  Future<Shipment> createShipment({
    required String senderId,
    required String pickupCity,
    required String dropoffCity,
    String? pickupLocationId,
    String? dropoffLocationId,
    double? weightKg,
    String? description,
    String? transportType,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
  }) async {
    final payload = {
      'sender_id': senderId,
      'pickup_location_id': pickupLocationId,
      'dropoff_location_id': dropoffLocationId,

      'weight_kg': weightKg,
      'description': description,
      'transport_type': transportType ?? 'internal',

      'status': ShipmentStatus.pending.toStringValue(),
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
    };

    try {
      final response = await _client
          .from('shipments')
          .insert(payload)
          .select()
          .single();
      final shipment = Shipment.fromJson(response);

      // Notify travelers whose shipment alerts match this shipment.
      // Intentionally fire-and-forget: notification failure must not block shipment creation.
      unawaited(_notifyMatchingTravelers(shipment));

      return shipment;
    } catch (e, st) {
      StructuredLogger.error('ShipmentService', 'createShipment failed', e, st);
      throw TripShipException.withKey(
        'failed_create_shipment',
        'Failed to create shipment. Please try again.',
        e,
      );
    }
  }

  /// Updates a pending shipment's editable fields (locations, weight, description).
  /// Only allowed while the shipment is [pending] or [inCommunication].
  Future<Shipment> updateShipment({
    required String shipmentId,
    required String pickupLocationId,
    required String dropoffLocationId,
    double? weightKg,
    String? description,
  }) async {
    try {
      final response = await _client
          .from('shipments')
          .update({
            'pickup_location_id': pickupLocationId,
            'dropoff_location_id': dropoffLocationId,
            'weight_kg': weightKg,
            'description': description,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', shipmentId)
          .inFilter('status', [
            ShipmentStatus.pending.toStringValue(),
            ShipmentStatus.inCommunication.toStringValue(),
          ])
          .select()
          .single();
      return Shipment.fromJson(response);
    } catch (e, st) {
      StructuredLogger.error('ShipmentService', 'updateShipment failed', e, st);
      throw TripShipException.withKey(
        'failed_update_shipment',
        'Failed to update shipment. It may have already been accepted.',
        e,
      );
    }
  }

  Future<void> _notifyMatchingTravelers(Shipment shipment) async {
    try {
      final pickupId = shipment.pickupLocationId;
      final dropoffId = shipment.dropoffLocationId;

      bool isInternal = shipment.transportType == 'internal';

      final matchingUserIds = await _ref
          .read(shipmentAlertServiceProvider)
          .getMatchingAlertUserIds(
            shipmentId: shipment.id,
            originLocationId: pickupId,
            destLocationId: dropoffId,
            isInternal: isInternal,
            excludeUserId: shipment.senderId,
          );

      if (matchingUserIds.isEmpty) {
        return;
      }

      final l10n = _ref.read(appLocalizationsProvider);
      final notifService = _ref.read(notificationServiceProvider);

      for (final userId in matchingUserIds) {
        await notifService.sendNotificationToUser(
          userId: userId,
          title: l10n.notifNewShipmentMatchingAlert,
          body: l10n.notifNewShipmentMatchingAlertBody,
          data: {
            'type': 'new_shipment_matching_alert',
            'shipment_id': shipment.id,
            'pickup_location_id': pickupId,
            'dropoff_location_id': dropoffId,
          },
          recipientRole: 'traveler',
        );
      }
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentService',
        'Error notifying matching travelers',
        e,
        st,
      );
    }
  }

  /// Fetch recent shipments with transport type filter and pagination.
  /// Uses server-side RPC for optimized filtering.
  ///
  /// When [excludeOfferedByCurrentUser] is `true` the RPC will omit any
  /// shipments for which the currently authenticated traveler already has a
  /// non-cancelled offer, so the traveler home screen only shows fresh work.
  Future<List<Shipment>> getRecentShipments({
    String? transportType,
    String? pickupLocationId,
    String? dropoffLocationId,
    String? pickupProvince,
    String? dropoffProvince,
    double? minWeight,
    DateTime? date,
    int limit = 20,
    int offset = 0,
    bool excludeOfferedByCurrentUser = false,
  }) async {
    try {
      final dateStr = date?.toIso8601String().split('T').first;
      final travelerId = excludeOfferedByCurrentUser
          ? _client.auth.currentUser?.id
          : null;
      final response = await _client.rpc(
        'search_shipments_rpc',
        params: {
          if (transportType != null) 'p_transport_type': transportType,
          if (pickupLocationId != null)
            'p_pickup_location_id': pickupLocationId,
          if (dropoffLocationId != null)
            'p_dropoff_location_id': dropoffLocationId,
          if (minWeight != null) 'p_min_weight': minWeight,
          if (dateStr != null) 'p_date': dateStr,
          if (pickupProvince != null) 'p_pickup_province': pickupProvince,
          if (dropoffProvince != null) 'p_dropoff_province': dropoffProvince,
          'p_limit': limit,
          'p_offset': offset,
          'p_traveler_id': travelerId,
        },
      );

      final shipments = (response as List)
          .map((e) => Shipment.fromJson(e))
          .toList();
      _sortFeaturedShipmentsFirst(shipments);
      return shipments;
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentService',
        'getRecentShipments failed',
        e,
        st,
      );
      throw TripShipException.withKey(
        'failed_load_shipments',
        'Failed to load shipments. Please try again.',
        e,
      );
    }
  }

  void _sortFeaturedShipmentsFirst(List<Shipment> shipments) {
    shipments.sort((a, b) {
      final featuredCompare = _profilePriority(
        b.sender?.isFeatured == true,
        b.sender?.promotedUntil,
      ).compareTo(
        _profilePriority(
          a.sender?.isFeatured == true,
          a.sender?.promotedUntil,
        ),
      );
      if (featuredCompare != 0) return featuredCompare;

      return b.createdAt.compareTo(a.createdAt);
    });
  }

  int _profilePriority(bool isFeatured, DateTime? promotedUntil) {
    if (isFeatured) return 2;
    if (promotedUntil != null && promotedUntil.isAfter(DateTime.now())) {
      return 1;
    }
    return 0;
  }

  Future<void> updateShipmentStatus(
    String shipmentId,
    ShipmentStatus status,
  ) async {
    try {
      // Guard: validate state transition
      final current = await _client
          .from('shipments')
          .select('status')
          .eq('id', shipmentId)
          .single();
      final currentStatus = ShipmentStatus.fromString(
        current['status'] as String?,
      );
      if (!currentStatus.canTransitionTo(status)) {
        throw TripShipException.withKey(
          'invalid_status_transition',
          'Cannot transition from ${currentStatus.toStringValue()} to ${status.toStringValue()}.',
        );
      }

      await _client
          .from('shipments')
          .update({'status': status.toStringValue()})
          .eq('id', shipmentId);
    } catch (e, st) {
      if (e is TripShipException) rethrow;
      StructuredLogger.error(
        'ShipmentService',
        'updateShipmentStatus failed',
        e,
        st,
      );
      throw TripShipException.withKey(
        'failed_update_shipment_status',
        'Failed to update shipment status.',
        e,
      );
    }
  }

  Future<void> deleteShipment(String shipmentId) async {
    try {
      // PRD: Only allow deleting if status is pending or in_communication
      final shipment = await getShipmentById(shipmentId);
      if (shipment.status != ShipmentStatus.pending &&
          shipment.status != ShipmentStatus.inCommunication) {
        throw TripShipException.withKey(
          'cannot_delete_active_shipment',
          'Cannot delete shipment: it is already booked or in transit.',
        );
      }

      await _client.from('shipments').delete().eq('id', shipmentId);
    } catch (e, st) {
      StructuredLogger.error('ShipmentService', 'deleteShipment failed', e, st);
      rethrow;
    }
  }

  /// Cancel an accepted shipment (before goods are received by driver).
  Future<void> cancelShipment(String shipmentId) async {
    try {
      final shipment = await getShipmentById(shipmentId);
      if (shipment.goodsReceivedByDriverAt != null) {
        throw TripShipException.withKey(
          'cannot_cancel_after_pickup',
          'Cannot cancel: goods already received by driver.',
        );
      }
      await updateShipmentStatus(shipmentId, ShipmentStatus.cancelled);
    } catch (e, st) {
      StructuredLogger.error('ShipmentService', 'cancelShipment failed', e, st);
      rethrow;
    }
  }

  Future<Shipment> getShipmentById(String id) async {
    try {
      final response = await _client
          .from('shipments')
          .select(
            '*, pickup_loc:locations!shipments_pickup_location_id_fkey!inner(*), '
            'dropoff_loc:locations!shipments_dropoff_location_id_fkey!inner(*), profiles(*)',
          )
          .eq('id', id)
          .single();
      return Shipment.fromJson(response);
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentService',
        'getShipmentById failed',
        e,
        st,
      );
      throw TripShipException.withKey(
        'failed_load_shipment_details',
        'Failed to load shipment details.',
        e,
      );
    }
  }

  /// Get shipments posted by the current user.
  Future<List<Shipment>> getMyShipments() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('shipments')
        .select(
          '*, pickup_loc:locations!shipments_pickup_location_id_fkey!inner(*), dropoff_loc:locations!shipments_dropoff_location_id_fkey!inner(*)',
        )
        .eq('sender_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Shipment.fromJson(e)).toList();
  }

  /// Realtime stream of shipments posted by the current user.
  Stream<List<Shipment>> watchMyShipments() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return _client
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('sender_id', userId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) async => await getMyShipments());
  }

  /// Realtime stream of a specific shipment.
  Stream<Shipment> watchShipment(String id) {
    return _client
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) => getShipmentById(id));
  }

  // --- Tracking Lifecycle Action Methods ---

  Future<void> markGoodsHandedOver(String shipmentId) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .markGoodsHandedOver(shipmentId);
  }

  Future<void> confirmGoodsReceived(String shipmentId) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .confirmGoodsReceived(shipmentId);
  }

  Future<void> markPaymentSent(String shipmentId) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .markPaymentSent(shipmentId);
  }

  Future<void> confirmPaymentReceived(String shipmentId) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .confirmPaymentReceived(shipmentId);
  }

  Future<void> markGoodsDeliveredWithCode(
    String shipmentId,
    String code,
  ) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .markGoodsDeliveredWithCode(shipmentId, code);
  }

  Future<void> markGoodsDelivered(String shipmentId) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .markGoodsDelivered(shipmentId);
  }

  Future<void> confirmGoodsReceivedByClient(String shipmentId) async {
    await _ref
        .read(shipmentLifecycleManagerProvider)
        .confirmGoodsReceivedByClient(shipmentId);
  }
}
