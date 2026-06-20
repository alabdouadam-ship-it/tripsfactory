import 'package:tripship/core/utils/stream_extensions.dart';
import 'package:tripship/core/utils/notification_location_helper.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/providers/app_localizations_provider.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/bookings/data/booking_lifecycle_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final bookingServiceProvider = Provider((ref) => BookingService(ref));

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Ref _ref;

  BookingService(this._ref);

  Future<List<Booking>> getBookingsForTrip(String tripId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
          *,
          requester:profiles!requester_id(id, full_name, avatar_url)
        ''')
          .eq('trip_id', tripId);
      final rawList = response as List;
      return rawList.map((e) => Booking.fromJson(e)).toList();
    } catch (e) {
      StructuredLogger.error(
        'BookingService',
        'Fetch bookings for trip failed',
        e,
      );
      return [];
    }
  }

  Stream<List<Booking>> watchBookingsForTrip(String tripId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) async {
          return await getBookingsForTrip(tripId);
        });
  }

  // Create a direct booking request without a separate listing
  Future<void> createDirectBooking({
    required String userId,
    required String driverId,
    required String tripId,
  }) async {
    final blockingStatuses = [
      BookingStatus.pending.toStringValue(),
      BookingStatus.accepted.toStringValue(),
      BookingStatus.inTransit.toStringValue(),
      BookingStatus.delivered.toStringValue(),
      BookingStatus.inCommunication.toStringValue(),
    ];

    Map<String, dynamic>? existing;
    try {
      existing = await _supabase
          .from('bookings')
          .select('id, status, timeline')
          .eq('trip_id', tripId)
          .eq('requester_id', userId)
          .inFilter('status', blockingStatuses)
          .limit(1)
          .maybeSingle();
    } on PostgrestException {
      existing = null;
    }

    if (existing != null) {
      if (existing['status'] == BookingStatus.inCommunication.toStringValue()) {
        // Upgrade to Pending (delivery code is generated server-side)
        await _supabase
            .from('bookings')
            .update({
              'status': BookingStatus.pending.toStringValue(),
              'timeline': (existing['timeline'] as List? ?? [])
                ..add({
                  'event': 'booking_request_created',
                  'timestamp': DateTime.now().toUtc().toIso8601String(),
                  'user_id': userId,
                  'message': 'Upgraded from inquiry',
                }),
            })
            .eq('id', existing['id']);

        // Notify driver about the upgrade (Treat as new request)
        final notifData = {'type': 'new_booking', 'trip_id': tripId};
        await NotificationLocationHelper.addOriginDestinationToData(
          _supabase,
          notifData,
          tripId,
        );

        final l10n = _ref.read(appLocalizationsProvider);
        await _ref
            .read(notificationServiceProvider)
            .sendNotificationToUser(
              userId: driverId,
              title: l10n.notifNewBookingRequest,
              body: l10n.notifNewBookingRequestBody,
              data: notifData,
              recipientRole: 'traveler',
            );
        return; // Done
      } else {
        throw TripShipException.withKey(
          'booking_request_exists',
          'You already have a booking request for this trip.',
        );
      }
    }

    // Create NEW if not exists (delivery code is generated server-side)
    await _supabase.from('bookings').insert({
      'traveler_id': driverId,
      'trip_id': tripId,
      'requester_id': userId, // Track who created this booking
      'price': 0.0, // Price to be negotiated
      'status': BookingStatus.pending.toStringValue(),
      'timeline': [
        {
          'event': 'booking_request_created',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'user_id': userId,
        },
      ],
    });

    // Update trip status to pendingConfirmation
    await _ref
        .read(bookingLifecycleManagerProvider)
        .updateTripStatus(tripId, TripStatus.pendingConfirmation);

    // Send notification to driver
    final notifData = {'type': 'new_booking', 'trip_id': tripId};
    await NotificationLocationHelper.addOriginDestinationToData(
      _supabase,
      notifData,
      tripId,
    );

    final l10n = _ref.read(appLocalizationsProvider);
    await _ref
        .read(notificationServiceProvider)
        .sendNotificationToUser(
          userId: driverId,
          title: l10n.notifNewBookingRequest,
          body: l10n.notifNewBookingRequestBody,
          data: notifData,
          recipientRole: 'traveler',
        );
  }

  // Find existing booking for communication, or null if none (create on first message)
  Future<String?> findExistingCommunication({
    required String tripId,
    required String driverId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final existing = await _supabase
        .from('bookings')
        .select('id')
        .eq('trip_id', tripId)
        .eq('requester_id', userId)
        .limit(1)
        .maybeSingle();

    return existing?['id'] as String?;
  }

  // Create booking + first message (only when user sends first message)
  Future<String> createBookingWithFirstMessage({
    required String tripId,
    required String driverId,
    required String firstMessageContent,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _supabase
        .from('bookings')
        .insert({
          'traveler_id': driverId,
          'trip_id': tripId,
          'requester_id': userId,
          'price': 0.0,
          'status': BookingStatus.inCommunication.toStringValue(),
          'timeline': [
            {
              'event': 'communication_started',
              'timestamp': now,
              'user_id': userId,
              'body': type == 'audio' ? 'Voice Message' : firstMessageContent,
            },
          ],
        })
        .select('id')
        .single();

    final bookingId = response['id'] as String;
    final insertData = <String, dynamic>{
      'booking_id': bookingId,
      'sender_id': userId,
      'content': firstMessageContent,
    };
    if (type != null) insertData['type'] = type;
    if (metadata != null) insertData['metadata'] = metadata;

    await _supabase.from('messages').insert(insertData);

    return bookingId;
  }

  // Check if current user has a booking for a specific trip
  Future<Booking?> getUserBookingForTrip(String tripId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      StructuredLogger.info(
        'BookingService',
        'getUserBookingForTrip: No user logged in',
      );
      return null;
    }

    StructuredLogger.info(
      'BookingService',
      'getUserBookingForTrip: tripId=$tripId, userId=$userId',
    );

    try {
      final response = await _supabase
          .from('bookings')
          .select('*')
          .eq('trip_id', tripId)
          .eq('requester_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return Booking.fromJson(response);
      }
    } catch (e) {
      StructuredLogger.error(
        'BookingService',
        'getUserBookingForTrip failed',
        e,
      );
    }

    return null;
  }

  Stream<Booking?> watchUserBookingForTrip(String tripId) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(null);
    }
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .map((rows) {
          // Parse directly from the stream payload — getUserBookingForTrip uses
          // SELECT * (no JOINs) so the stream already carries all needed fields.
          // This eliminates a redundant secondary DB round-trip on every event.
          final userRows =
              rows.where((r) => r['requester_id'] == userId).toList()
                ..sort((a, b) {
                  final aTs = a['created_at'] as String? ?? '';
                  final bTs = b['created_at'] as String? ?? '';
                  return bTs.compareTo(aTs); // newest first
                });
          if (userRows.isEmpty) return null;
          try {
            return Booking.fromJson(userRows.first);
          } catch (e) {
            // Fallback: row may have insufficient data; callers handle null gracefully
            return null;
          }
        });
  }

  // Get bookings where I am the requester (Client View: "My Requests / Talabati")
  Future<List<Booking>> getMyRequests() async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final response = await _supabase
          .from('bookings')
          .select(
            '*, driver:profiles!traveler_id(id, full_name, avatar_url), trips!inner(*, origin_loc:locations!origin_location_id(*), dest_loc:locations!dest_location_id(*))',
          )
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      final rawList = response as List;
      final results = <Booking>[];
      for (final rawItem in rawList) {
        try {
          final e = Map<String, dynamic>.from(rawItem as Map);
          if (e['driver'] != null) {
            final driver = Map<String, dynamic>.from(e['driver'] as Map);
            // Defend against nulls in required fields from Supabase
            if (driver['id'] == null) {
              driver['id'] = e['traveler_id'] ?? 'unknown_id';
            }
            if (driver['full_name'] == null) {
              driver['full_name'] = 'Unknown User';
            }
            e['driver'] = driver;
          }
          if (e['requester'] != null) {
            final requester = Map<String, dynamic>.from(e['requester'] as Map);
            if (requester['id'] == null) {
              requester['id'] = e['requester_id'] ?? 'unknown_id';
            }
            if (requester['full_name'] == null) {
              requester['full_name'] = 'Unknown User';
            }
            e['requester'] = requester;
          }
          results.add(Booking.fromJson(e));
        } catch (err, st) {
          StructuredLogger.error(
            'BookingService',
            'Failed parsing single booking: $rawItem',
            err,
            st,
          );
        }
      }
      return results;
    } catch (e) {
      StructuredLogger.error('BookingService', 'getMyRequests failed', e);
      return [];
    }
  }

  /// Realtime stream of my requests (trip-based bookings where I am the requester).
  Stream<List<Booking>> watchMyRequests() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('requester_id', userId)
        .throttle(const Duration(milliseconds: 300))
        .distinctUntilDataChanged()
        .asyncMap((_) => getMyRequests());
  }

  /// Returns the current status of a booking, or null if not found.
  Future<BookingStatus?> getBookingStatus(String bookingId) async {
    final row = await _supabase
        .from('bookings')
        .select('status')
        .eq('id', bookingId)
        .maybeSingle();
    if (row == null) return null;
    return BookingStatus.fromString(row['status'] as String?);
  }

  /// Returns recipient_role ('sender' | 'traveler') for a user in a booking.
  /// Used for chat notifications so they appear in the correct mode.
  Future<String?> getRecipientRoleForUser(
    String bookingId,
    String userId,
  ) async {
    final row = await _supabase
        .from('bookings')
        .select('requester_id, traveler_id')
        .eq('id', bookingId)
        .maybeSingle();
    if (row == null) return null;
    final requesterId = row['requester_id'] as String?;
    final travelerId = row['traveler_id'] as String?;
    if (requesterId == userId) return 'sender';
    if (travelerId == userId) return 'traveler';
    return null;
  }
}
