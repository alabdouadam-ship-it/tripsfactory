import 'package:tripship/core/utils/notification_location_helper.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> applyNotificationEnrichmentShape(
  Map<String, dynamic> base, {
  Object? tripId,
  String? travelerId,
  String? travelerName,
}) {
  final data = Map<String, dynamic>.from(base);
  if (tripId != null) {
    data['trip_id'] = tripId;
  }
  if (travelerId != null) {
    data['other_user_id'] = travelerId;
    data['traveler_id'] = travelerId;
  }
  if (travelerName != null) {
    data['other_user_name'] = travelerName;
  }
  return data;
}

class BookingNotificationEnrichmentService {
  BookingNotificationEnrichmentService(this._supabase);

  final SupabaseClient _supabase;

  Future<String?> getSenderIdForBooking(String bookingId) async {
    final booking = await _supabase
        .from('bookings')
        .select('requester_id')
        .eq('id', bookingId)
        .maybeSingle();
    if (booking == null) return null;
    return booking['requester_id'] as String?;
  }

  Future<Map<String, dynamic>> enrichNotificationDataForBooking(
    String bookingId,
    Map<String, dynamic> base, {
    Map<String, dynamic>? bookingData,
  }) async {
    var data = Map<String, dynamic>.from(base);
    try {
      final booking =
          bookingData ??
          await _supabase
              .from('bookings')
              .select('trip_id, traveler_id')
              .eq('id', bookingId)
              .maybeSingle();
      if (booking == null) return data;
      final tripId = booking['trip_id'];
      final travelerId = booking['traveler_id'] as String?;
      String? travelerName;
      if (travelerId != null) {
        final profile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', travelerId)
            .maybeSingle();
        if (profile != null && profile['full_name'] != null) {
          travelerName = profile['full_name'] as String;
        }
      }
      data = applyNotificationEnrichmentShape(
        data,
        tripId: tripId,
        travelerId: travelerId,
        travelerName: travelerName,
      );
      await NotificationLocationHelper.addOriginDestinationToData(
        _supabase,
        data,
        data['trip_id'],
      );
      return data;
    } catch (e, stack) {
      StructuredLogger.error(
        'BookingNotificationEnrichmentService',
        'Enrichment failed, falling back to base notification data',
        e,
        stack,
      );
      return data;
    }
  }
}
