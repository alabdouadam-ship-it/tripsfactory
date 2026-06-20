import 'dart:convert';
import 'package:tripsfactory/core/utils/stream_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/data/route_alert_service.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/core/config/geography_config.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/services/notification_service.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:tripsfactory/core/providers/app_localizations_provider.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(Supabase.instance.client, ref);
});

/// Session-level cache for the locations list.
/// Locations change very rarely; fetching them once per session is sufficient.
/// Invalidate via ref.invalidate(locationsProvider) if the user forces a refresh.
final locationsProvider = FutureProvider<List<Location>>((ref) async {
  return ref.read(tripServiceProvider).getLocations();
});

class TripService {
  final SupabaseClient _client;
  final Ref _ref;

  TripService(this._client, this._ref);

  Future<void> createTrip({
    required String driverId,
    required String originLocationId,
    required String destLocationId,
    required DateTime departureTime,
    double? maxWeight,
    double? suggestedFlatPrice,
    String? notes,
  }) async {
    // 1. Guard: Check Driver Validity
    final profileResponse = await _client
        .from('profiles')
        .select('is_suspended, subscription_expires_at, license_expires_at')
        .eq('id', driverId)
        .single();
    if (profileResponse['is_suspended'] == true) {
      throw TripsFactoryException.withKey('account_suspended', 'Account suspended.');
    }

    final subExpiry = profileResponse['subscription_expires_at'] != null
        ? DateTime.parse(profileResponse['subscription_expires_at'])
        : null;
    final licenseExpiry = profileResponse['license_expires_at'] != null
        ? DateTime.parse(profileResponse['license_expires_at'])
        : null;

    if ((subExpiry != null && subExpiry.isBefore(DateTime.now())) ||
        (licenseExpiry != null && licenseExpiry.isBefore(DateTime.now()))) {
      throw TripsFactoryException.withKey(
        'credentials_expired',
        'Credentials expired.',
      );
    }

    final payload = {
      'traveler_id': driverId,
      'origin_location_id': originLocationId,
      'dest_location_id': destLocationId,
      'departure_time': departureTime.toUtc().toIso8601String(),
      'max_weight_kg': maxWeight,
      'suggested_price_per_kg': null,
      'suggested_flat_price': suggestedFlatPrice,
      'notes': notes,
      'trip_type': 'scheduled',
      'status': TripStatus.available.toStringValue(),
    };

    final tripResponse = await _client
        .from('trips')
        .insert(payload)
        .select('id')
        .single();
    final tripId = tripResponse['id'];

    // Notify users whose route alerts match this trip
    try {
      final locs = await _client
          .from('locations')
          .select('id, country_code, country_name_en, country_name_ar')
          .inFilter('id', [originLocationId, destLocationId]);
      bool isInternal = true;
      for (final loc in locs as List) {
        final code = (loc['country_code'] ?? '').toString();
        final en = (loc['country_name_en'] ?? '').toString();
        final ar = (loc['country_name_ar'] ?? '').toString();
        final hasIdentity = code.isNotEmpty || en.isNotEmpty;
        if (hasIdentity &&
            !GeographyConfig.isHomeCountry(
              code: code,
              nameEn: en,
              nameAr: ar,
            )) {
          isInternal = false;
          break;
        }
      }

      final matchingUserIds = await _ref
          .read(routeAlertServiceProvider)
          .getMatchingAlertUserIds(
            tripId: tripId,
            originLocationId: originLocationId,
            destLocationId: destLocationId,
            isInternal: isInternal,
            excludeUserId: driverId,
          );

      final l10n = _ref.read(appLocalizationsProvider);
      final notifService = _ref.read(notificationServiceProvider);
      for (final userId in matchingUserIds) {
        await notifService.sendNotificationToUser(
          userId: userId,
          title: l10n.notifNewTripMatchingAlert,
          body: l10n.notifNewTripMatchingAlertBody,
          data: {
            'type': 'new_trip_matching_alert',
            'trip_id': tripId,
            'origin_location_id': originLocationId,
            'dest_location_id': destLocationId,
          },
          recipientRole: 'sender',
        );
      }
    } catch (_) {
      // Don't fail trip creation if notification fails
    }
  }

  // Fetch trips with advanced filtering
  Future<List<Trip>> searchTrips({
    required bool isInternal,
    String? currentUserId, // Filter out trips user has interacted with
    String? vehicleType,
    String? originCity,
    String? destinationCity,
    String? originLocationId,
    String? destLocationId,
    double? minWeight,
    DateTime? date,
    String? originProvince, // Renamed from province
    String? destProvince, // New
    String? city,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Start with a basic select including relations
      // Use RPC for optimized server-side filtering
      final dateStr = date?.toIso8601String().split('T')[0];
      final response = await _client.rpc(
        'search_trips_rpc',
        params: {
          'p_origin_city': ?originCity,
          'p_dest_city': ?destinationCity,
          'p_origin_location_id': ?originLocationId,
          'p_dest_location_id': ?destLocationId,
          'p_is_internal': isInternal,
          'p_vehicle_type': ?vehicleType,
          'p_min_weight': ?minWeight,
          'p_departure_date': ?dateStr,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      // Map to Trip objects
      var trips = (response as List).map((e) => Trip.fromJson(e)).toList();

      // 4. User Interaction Filter (Async)
      // This remains client-side as it depends on local user state/blocking
      if (currentUserId != null) {
        final userInteractedTripIds = await _getUserInteractedTripIds(
          currentUserId,
        );
        trips = trips
            .where(
              (trip) =>
                  trip.driverId != currentUserId &&
                  !userInteractedTripIds.contains(trip.id),
            )
            .toList();
      }

      _sortFeaturedTripsFirst(trips);
      return trips;
    } catch (e, st) {
      StructuredLogger.error(
        'TripService',
        'Error fetching recent trips: $e',
        e,
        st,
      );
      if (e is TripsFactoryException) rethrow;
      throw TripsFactoryException.withKey(
        'failed_fetch_trips',
        'Error fetching recent trips: $e',
        e,
      );
    }
  }

  void _sortFeaturedTripsFirst(List<Trip> trips) {
    trips.sort((a, b) {
      final featuredCompare =
          _profilePriority(
            b.driver?.isFeatured == true,
            b.driver?.promotedUntil,
          ).compareTo(
            _profilePriority(
              a.driver?.isFeatured == true,
              a.driver?.promotedUntil,
            ),
          );
      if (featuredCompare != 0) return featuredCompare;

      final departureCompare = a.departureTime.compareTo(b.departureTime);
      if (departureCompare != 0) return departureCompare;

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

  Future<Trip?> getTripById(String tripId) async {
    try {
      final response = await _client
          .from('trips')
          .select(
            '*, origin_loc:locations!origin_location_id(*), dest_loc:locations!dest_location_id(*), driver:profiles(*, vehicles:vehicles_public(*))',
          )
          .eq('id', tripId)
          .maybeSingle();
      if (response == null) return null;
      return Trip.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Stream<Trip> watchTrip(String tripId) {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((data) async {
          if (data.isEmpty) {
            throw TripsFactoryException.withKey(
              'trip_not_found',
              'Trip deleted or not found.',
            );
          }
          final trip = await getTripById(tripId);
          if (trip == null) {
            throw TripsFactoryException.withKey(
              'trip_not_found',
              'Trip deleted or not found.',
            );
          }
          return trip;
        });
  }

  // Get My Trips (Traveler)
  Future<List<Trip>> getMyTrips(String driverId) async {
    final response = await _client
        .from('trips')
        .select(
          '*, origin_loc:locations!origin_location_id(*), dest_loc:locations!dest_location_id(*), driver:profiles(*, vehicles:vehicles_public(*))',
        )
        .eq('traveler_id', driverId)
        .order('created_at', ascending: false);

    final List<Trip> trips = [];
    for (final e in (response as List)) {
      try {
        trips.add(Trip.fromJson(e));
      } catch (err, st) {
        StructuredLogger.error(
          'TripService',
          'Failed to parse trip: $err',
          err,
          st,
        );
      }
    }

    // Note: Auto-expire is handled server-side by the 'auto-expire-trips'
    // Edge Function running on a 15-minute cron schedule.

    return trips;
  }

  Stream<List<Trip>> watchMyTrips(String driverId) {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('traveler_id', driverId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) async {
          return await getMyTrips(driverId);
        });
  }

  Future<void> cancelTrip(String tripId) async {
    // Safety Check: Cannot cancel if any booking has goods received, payment confirmed, or goods delivered
    final bookings = await _client
        .from('bookings')
        .select(
          'status, goods_received_by_traveler_at, goods_received_by_client_at, payment_confirmed_by_traveler_at',
        )
        .eq('trip_id', tripId);

    for (final booking in bookings) {
      final status = booking['status'];
      final goodsReceivedByTraveler = booking['goods_received_by_traveler_at'];
      final goodsReceivedByClient = booking['goods_received_by_client_at'];
      final paidAt = booking['payment_confirmed_by_traveler_at'];

      if (status == BookingStatus.inTransit.toStringValue() ||
          status == BookingStatus.delivered.toStringValue() ||
          status == BookingStatus.completed.toStringValue() ||
          goodsReceivedByTraveler != null ||
          goodsReceivedByClient != null ||
          paidAt != null) {
        throw TripsFactoryException.withKey(
          'cannot_cancel_trip_active_bookings',
          'Cannot cancel trip: Contains active bookings that are in transit, delivered, or paid.',
        );
      }
    }

    await _client
        .from('trips')
        .update({'status': TripStatus.cancelled.toStringValue()})
        .eq('id', tripId);

    // Auto-reject all pending and inCommunication bookings
    await _client
        .from('bookings')
        .update({'status': BookingStatus.rejected.toStringValue()})
        .eq('trip_id', tripId)
        .inFilter('status', [
          BookingStatus.pending.toStringValue(),
          BookingStatus.inCommunication.toStringValue(),
        ]);
  }

  // Mark trip as full (driver manually or auto after first delivery)
  // Also auto-rejects all pending and inCommunication bookings
  Future<void> markTripAsFull(String tripId) async {
    await _client
        .from('trips')
        .update({'status': TripStatus.full.toStringValue()})
        .eq('id', tripId);

    // Auto-reject all pending and inCommunication bookings
    await _client
        .from('bookings')
        .update({'status': BookingStatus.rejected.toStringValue()})
        .eq('trip_id', tripId)
        .inFilter('status', [
          BookingStatus.pending.toStringValue(),
          BookingStatus.inCommunication.toStringValue(),
        ]);
  }

  // Get list of trip IDs that the user has interacted with (has bookings for)
  Future<Set<String>> _getUserInteractedTripIds(String userId) async {
    try {
      final bookings = await _client
          .from('bookings')
          .select('trip_id')
          .eq('requester_id', userId)
          .not('trip_id', 'is', null);

      return bookings
          .map((b) => b['trip_id'] as String)
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      // If requester_id column doesn't exist yet, return empty set
      return <String>{};
    }
  }

  Future<List<Location>> getLocations() async {
    try {
      final prefs = _ref.read(preferencesServiceProvider);
      const cacheKey = 'cached_locations_v2_active';
      final cachedJson = await prefs.getString(cacheKey);

      if (cachedJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded.map((e) => Location.fromJson(e)).toList();
        } catch (e) {
          // Ignore cache parse error, fetch from network
        }
      }

      final response = await _client
          .from('locations')
          .select()
          .eq('is_active', true)
          .order('city_name_ar');

      final locs = (response as List).map((e) => Location.fromJson(e)).toList();

      // Save to cache asynchronously
      prefs.setString(cacheKey, jsonEncode(response));

      return locs;
    } catch (e) {
      StructuredLogger.error('TripService', 'Failed to fetch locations', e);
      return [];
    }
  }

  Future<Map<String, BookingStatus>> getBookingStatusesForTrips(
    List<String> tripIds,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || tripIds.isEmpty) return {};

    try {
      final response = await _client
          .from('bookings')
          .select('trip_id, status')
          .inFilter('trip_id', tripIds)
          .eq('requester_id', userId);

      final Map<String, BookingStatus> result = {};
      for (var item in response) {
        final tripId = item['trip_id'] as String;
        final status = BookingStatus.fromString(item['status']);
        result[tripId] = status;
      }
      return result;
    } catch (e) {
      StructuredLogger.error(
        'TripService',
        'getBookingStatusesForTrips failed',
        e,
      );
      return {};
    }
  }
}
