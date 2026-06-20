import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_status_sync_rules.dart';

/// Trip status side-effects for booking lifecycle (optimistic client updates).
class TripStatusSyncService {
  TripStatusSyncService(this._supabase);

  final SupabaseClient _supabase;

  /// Auto-mark trip as full when any booking reaches delivered/completed.
  Future<void> autoMarkTripFullIfNeeded(String tripId) async {
    try {
      final trip = await _supabase
          .from('trips')
          .select('status')
          .eq('id', tripId)
          .single();
      final currentStatus = TripStatus.fromString(trip['status'] as String?);
      if (tripStatusAllowsAutoMarkFull(currentStatus)) {
        await _supabase
            .from('trips')
            .update({'status': TripStatus.full.toStringValue()})
            .eq('id', tripId);
        await _supabase
            .from('bookings')
            .update({'status': BookingStatus.rejected.toStringValue()})
            .eq('trip_id', tripId)
            .inFilter('status', [
              BookingStatus.pending.toStringValue(),
              BookingStatus.inCommunication.toStringValue(),
            ]);
      }
    } catch (e) {
      StructuredLogger.error(
        'TripStatusSyncService',
        'Auto-mark trip full failed',
        e,
      );
    }
  }

  /// Complete trip when all bookings are terminal and at least one completed.
  Future<void> checkAndCompleteTrip(String tripId) async {
    try {
      final allBookings = await _supabase
          .from('bookings')
          .select('status')
          .eq('trip_id', tripId);
      final list = allBookings as List;

      final statuses = list.map((b) => (b as Map)['status'] as String?);
      if (bookingsAllowTripComplete(statuses)) {
        await updateTripStatus(tripId, TripStatus.completed);
      }
    } catch (e) {
      StructuredLogger.error(
        'TripStatusSyncService',
        'Check and complete trip failed for $tripId',
        e,
      );
    }
  }

  Future<void> updateTripStatus(String tripId, TripStatus newStatus) async {
    try {
      final trip = await _supabase
          .from('trips')
          .select('status')
          .eq('id', tripId)
          .single();

      final currentStatus = TripStatus.fromString(trip['status']);

      if (currentStatus == TripStatus.completed ||
          currentStatus == TripStatus.cancelled) {
        return;
      }

      if (currentStatus == TripStatus.full &&
          newStatus != TripStatus.completed) {
        return;
      }

      await _supabase
          .from('trips')
          .update({'status': newStatus.toStringValue()})
          .eq('id', tripId);
    } catch (e) {
      StructuredLogger.error(
        'TripStatusSyncService',
        'Trip status update failed for $tripId',
        e,
      );
    }
  }
}
