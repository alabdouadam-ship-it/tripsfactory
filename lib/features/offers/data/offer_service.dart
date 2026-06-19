import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/utils/stream_extensions.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/providers/app_localizations_provider.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final offerServiceProvider = Provider((ref) => OfferService(ref));

class OfferService {
  static const String _logContext = 'OfferService';
  final SupabaseClient _supabase = Supabase.instance.client;
  final Ref _ref;

  OfferService(this._ref);

  /// Send an offer on a shipment with an initial message (driver → shipment owner).
  /// Uses the ACID-safe `send_offer_with_message` RPC which creates
  /// both the offer and the first chat message in one transaction.
  Future<Offer> sendOffer({
    required String shipmentId,
    required double price,
    required String message,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    try {
      StructuredLogger.info(_logContext, 'Sending offer', {
        'shipmentId': shipmentId,
        'driverId': userId,
        'price': price,
      });

      final offer = await _sendOfferWithMessageRpc(
        userId: userId,
        shipmentId: shipmentId,
        price: price,
        message: message,
      );

      await _notifyShipmentOwner(shipmentId);
      return offer;
    } on PostgrestException catch (e, st) {
      final lowerMessage = e.message.toLowerCase();

      // Compatibility fallback:
      // Some DBs may still have messages.booking_id as NOT NULL, which makes
      // the message insert inside send_offer_with_message fail.
      if (lowerMessage.contains('booking_id') &&
          lowerMessage.contains('not-null')) {
        StructuredLogger.warning(
          _logContext,
          'Fallback: booking_id not-null constrained. Retrying without message.',
          {'shipmentId': shipmentId},
        );
        final offer = await _sendOfferWithMessageRpc(
          userId: userId,
          shipmentId: shipmentId,
          price: price,
          message: null,
        );

        await _notifyShipmentOwner(shipmentId);
        return offer;
      }

      // Legacy fallback if the new RPC is not installed yet.
      if (lowerMessage.contains('send_offer_with_message') &&
          lowerMessage.contains('does not exist')) {
        StructuredLogger.warning(
          _logContext,
          'Fallback: send_offer_with_message RPC missing. Using legacy send_offer.',
          {'shipmentId': shipmentId},
        );
        final legacyResult = await _supabase.rpc(
          'send_offer',
          params: {
            'p_driver_id': userId,
            'p_shipment_id': shipmentId,
            'p_price': price,
          },
        );
        final offer = Offer.fromJson(legacyResult as Map<String, dynamic>);
        await _notifyShipmentOwner(shipmentId);
        return offer;
      }

      if (e.message.contains('SHIPMENT_ALREADY_ACCEPTED')) {
        throw TripShipException.withKey(
          'shipment_already_booked',
          'This shipment already has an accepted offer.',
        );
      }
      if (e.message.contains('SHIPMENT_NOT_FOUND')) {
        throw TripShipException.withKey(
          'shipment_not_found',
          'Shipment not found.',
        );
      }

      StructuredLogger.error(_logContext, 'Error sending offer', e, st, {
        'shipmentId': shipmentId,
      });
      rethrow;
    } catch (e, st) {
      StructuredLogger.error(
        _logContext,
        'Unexpected error sending offer',
        e,
        st,
        {'shipmentId': shipmentId},
      );
      throw TripShipException.fromObject(e);
    }
  }

  Future<Offer> _sendOfferWithMessageRpc({
    required String userId,
    required String shipmentId,
    required double price,
    required String? message,
  }) async {
    final result = await _supabase.rpc(
      'send_offer_with_message',
      params: {
        'p_driver_id': userId,
        'p_shipment_id': shipmentId,
        'p_price': price,
        'p_message': message,
      },
    );

    return Offer.fromJson(result as Map<String, dynamic>);
  }

  Future<void> _notifyShipmentOwner(String shipmentId) async {
    try {
      final shipment = await _supabase
          .from('shipments')
          .select('sender_id')
          .eq('id', shipmentId)
          .single();

      final l10n = _ref.read(appLocalizationsProvider);
      await _ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: shipment['sender_id'],
            title: l10n.notifNewOffer,
            body: l10n.notifNewOfferBody,
            data: {'type': 'new_offer', 'shipment_id': shipmentId},
            recipientRole: 'sender',
          );
    } catch (e) {
      StructuredLogger.warning(_logContext, 'Failed to notify shipment owner', {
        'shipmentId': shipmentId,
        'error': e.toString(),
      });
    }
  }

  /// Accept an offer (shipment owner accepts a driver's offer).
  /// Uses the ACID-safe `accept_offer` RPC.
  Future<void> acceptOffer(String offerId) async {
    final userId = _supabase.auth.currentUser!.id;

    try {
      StructuredLogger.info(_logContext, 'Accepting offer', {
        'offerId': offerId,
        'ownerId': userId,
      });

      await _supabase.rpc(
        'accept_offer',
        params: {'p_offer_id': offerId, 'p_shipment_owner_id': userId},
      );

      // Generate OTP delivery code for the shipment
      final offer = await _supabase
          .from('offers')
          .select('driver_id, shipment_id')
          .eq('id', offerId)
          .single();

      final shipmentId = offer['shipment_id'] as String;

      // Notify driver (general acceptance + safety warning)
      final l10n = _ref.read(appLocalizationsProvider);

      final notificationData = {
        'type': 'offer_accepted',
        'shipment_id': shipmentId,
        'offer_id': offerId,
      };

      await _ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: offer['driver_id'] as String,
            title: l10n.notifBookingApproved,
            body: l10n.notifOfferAcceptedBody,
            data: notificationData,
            recipientRole: 'traveler',
          );

      // Safety warning to Driver to check goods
      await _ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: offer['driver_id'] as String,
            title: l10n.warningCheckGoodsTitle,
            body: l10n.warningCheckGoodsBody,
            data: notificationData,
            recipientRole: 'traveler',
          );

      // Safety warning to Sender to check Driver ID
      await _ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: userId,
            title: l10n.warningCheckTravelerTitle,
            body: l10n.warningCheckTravelerBody,
            data: notificationData,
            recipientRole: 'sender',
          );
    } on PostgrestException catch (e, st) {
      if (e.message.contains('SHIPMENT_ALREADY_ACCEPTED')) {
        throw TripShipException.withKey(
          'shipment_already_booked',
          'Another offer was already accepted for this shipment.',
        );
      }
      if (e.message.contains('OFFER_NOT_SENT')) {
        throw TripShipException.withKey(
          'offer_not_pending',
          'This offer can no longer be accepted.',
        );
      }
      StructuredLogger.error(_logContext, 'Error accepting offer', e, st, {
        'offerId': offerId,
      });
      rethrow;
    } catch (e, st) {
      StructuredLogger.error(
        _logContext,
        'Unexpected error accepting offer',
        e,
        st,
        {'offerId': offerId},
      );
      throw TripShipException.fromObject(e);
    }
  }

  /// Reject an offer (shipment owner rejects a driver's offer).
  /// Uses the ACID-safe `reject_offer` RPC.
  Future<void> rejectOffer(String offerId) async {
    final userId = _supabase.auth.currentUser!.id;

    try {
      StructuredLogger.info(_logContext, 'Rejecting offer', {
        'offerId': offerId,
        'ownerId': userId,
      });

      await _supabase.rpc(
        'reject_offer',
        params: {'p_offer_id': offerId, 'p_shipment_owner_id': userId},
      );

      // Notify driver
      final offer = await _supabase
          .from('offers')
          .select('driver_id, shipment_id')
          .eq('id', offerId)
          .single();

      final l10n = _ref.read(appLocalizationsProvider);
      await _ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: offer['driver_id'] as String,
            title: l10n.notifOfferDeclined,
            body: l10n.notifOfferDeclinedBody,
            data: {
              'type': 'offer_rejected',
              'shipment_id': offer['shipment_id'],
            },
            recipientRole: 'traveler',
          );
    } on PostgrestException catch (e, st) {
      if (e.message.contains('INVALID_STATE')) {
        throw TripShipException.withKey(
          'offer_not_pending',
          'This offer can no longer be rejected.',
        );
      }
      StructuredLogger.error(_logContext, 'Error rejecting offer', e, st, {
        'offerId': offerId,
      });
      rethrow;
    } catch (e, st) {
      StructuredLogger.error(
        _logContext,
        'Unexpected error rejecting offer',
        e,
        st,
        {'offerId': offerId},
      );
      throw TripShipException.fromObject(e);
    }
  }

  /// Cancel an offer (driver cancels own sent offer).
  /// Uses the ACID-safe `cancel_offer` RPC.
  Future<void> cancelOffer(String offerId) async {
    final userId = _supabase.auth.currentUser!.id;

    try {
      StructuredLogger.info(_logContext, 'Cancelling offer', {
        'offerId': offerId,
        'driverId': userId,
      });

      await _supabase.rpc(
        'cancel_offer',
        params: {'p_offer_id': offerId, 'p_driver_id': userId},
      );
    } on PostgrestException catch (e, st) {
      if (e.message.contains('INVALID_STATE')) {
        throw TripShipException.withKey(
          'offer_not_pending',
          'This offer can no longer be cancelled.',
        );
      }
      StructuredLogger.error(_logContext, 'Error cancelling offer', e, st, {
        'offerId': offerId,
      });
      rethrow;
    } catch (e, st) {
      StructuredLogger.error(
        _logContext,
        'Unexpected error cancelling offer',
        e,
        st,
        {'offerId': offerId},
      );
      throw TripShipException.fromObject(e);
    }
  }

  /// Get all offers for a shipment (shipment owner view).
  Future<List<Offer>> getOffersForShipment(String shipmentId) async {
    try {
      final response = await _supabase
          .from('offers')
          .select(
            '*, profiles(id, full_name, avatar_url, traveler_rating_avg, traveler_type, is_trusted, is_featured, trust_badge)',
          )
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Offer.fromJson(e)).toList();
    } catch (e, st) {
      StructuredLogger.error(
        _logContext,
        'Error fetching offers for shipment',
        e,
        st,
        {'shipmentId': shipmentId},
      );
      return [];
    }
  }

  /// Batch fetch offer counts for multiple shipment IDs in ONE query.
  /// Returns {shipmentId: [offerStatuses]}.
  Future<Map<String, List<String>>> getOfferStatusesForShipments(
    List<String> shipmentIds,
  ) async {
    if (shipmentIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('offers')
          .select('shipment_id, status')
          .inFilter('shipment_id', shipmentIds);

      final result = <String, List<String>>{};
      for (final row in (response as List)) {
        final sid = row['shipment_id'] as String;
        result
            .putIfAbsent(sid, () => [])
            .add(row['status'] as String? ?? 'sent');
      }
      return result;
    } catch (e, st) {
      StructuredLogger.error(
        _logContext,
        'Error fetching offer statuses',
        e,
        st,
        {'count': shipmentIds.length},
      );
      return {};
    }
  }

  /// Realtime stream of offers for a shipment.
  Stream<List<Offer>> watchOffersForShipment(String shipmentId) {
    return _supabase
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('shipment_id', shipmentId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) async => await getOffersForShipment(shipmentId));
  }

  /// Get all offers made by the current driver.
  Future<List<Offer>> getMyOffers() async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final response = await _supabase
          .from('offers')
          .select(
            '*, profiles(id, full_name, avatar_url, traveler_rating_avg, traveler_type, is_trusted, is_featured, trust_badge), shipments(*, pickup_loc:locations!shipments_pickup_location_id_fkey(*), dropoff_loc:locations!shipments_dropoff_location_id_fkey(*), profiles(*))',
          )
          .eq('driver_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Offer.fromJson(e)).toList();
    } catch (e, st) {
      StructuredLogger.error(_logContext, 'Error fetching my offers', e, st, {
        'driverId': userId,
      });
      return [];
    }
  }

  /// Realtime stream of driver's own offers.
  Stream<List<Offer>> watchMyOffers() {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) async => await getMyOffers());
  }

  /// Get a single offer by ID with full details.
  Future<Offer> getOfferById(String id) async {
    try {
      final response = await _supabase
          .from('offers')
          .select(
            '*, profiles(id, full_name, avatar_url, traveler_rating_avg, traveler_type, is_trusted, is_featured, trust_badge), '
            'shipments(*, pickup_loc:locations!shipments_pickup_location_id_fkey(*), '
            'dropoff_loc:locations!shipments_dropoff_location_id_fkey(*), profiles(*))',
          )
          .eq('id', id)
          .single();

      return Offer.fromJson(response);
    } catch (e, st) {
      StructuredLogger.error(_logContext, 'Error fetching offer by ID', e, st, {
        'offerId': id,
      });
      rethrow;
    }
  }

  /// Realtime stream of a specific offer.
  Stream<Offer> watchOffer(String id) {
    return _supabase
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) => getOfferById(id));
  }
}
