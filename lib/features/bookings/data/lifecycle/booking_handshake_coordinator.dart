import 'package:tripship/core/enums/app_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'handshake_engine.dart';

/// Loads booking snapshot, evaluates handshake, persists update.
class BookingHandshakeCoordinator {
  BookingHandshakeCoordinator(
    this._supabase, {
    HandshakeEngine engine = const HandshakeEngine(),
  }) : _engine = engine;

  final SupabaseClient _supabase;
  final HandshakeEngine _engine;

  Future<void> applyHandshake({
    required String bookingId,
    required String timelineEvent,
    String? fieldName,
    BookingStatus? newStatus,
    Map<String, dynamic>? additionalUpdates,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final userId = _supabase.auth.currentUser!.id;

    final selectFields = HandshakeEngine.selectFields(fieldName: fieldName);
    final booking = await _supabase
        .from('bookings')
        .select(selectFields)
        .eq('id', bookingId)
        .single();

    final result = _engine.evaluate(
      bookingId: bookingId,
      timelineEvent: timelineEvent,
      nowIso: now,
      authUserId: userId,
      booking: Map<String, dynamic>.from(booking),
      fieldName: fieldName,
      newStatus: newStatus,
      additionalUpdates: additionalUpdates,
    );

    switch (result) {
      case HandshakeSkip():
        return;
      case HandshakeApply(:final updates):
        await _supabase.from('bookings').update(updates).eq('id', bookingId);
    }
  }
}
