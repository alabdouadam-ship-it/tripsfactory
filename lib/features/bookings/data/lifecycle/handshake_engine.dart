import 'package:tripship/core/enums/app_enums.dart';

import 'booking_state_machine.dart';

/// Result of evaluating a handshake update against a booking snapshot (no I/O).
sealed class HandshakeComputation {}

/// Skip persisting: idempotency or terminal guard or status already matches.
class HandshakeSkip extends HandshakeComputation {
  HandshakeSkip(this.reason);
  final HandshakeSkipReason reason;
}

enum HandshakeSkipReason {
  timestampAlreadySet,
  terminalBooking,
  statusAlreadyMatches,
}

/// Apply this map to `bookings` row.
class HandshakeApply extends HandshakeComputation {
  HandshakeApply(this.updates);
  final Map<String, dynamic> updates;
}

/// Pure handshake assembly + FSM checks (mirrors legacy `_updateHandshake` logic).
class HandshakeEngine {
  const HandshakeEngine({
    BookingStateMachine stateMachine = const BookingStateMachine(),
  }) : _stateMachine = stateMachine;

  final BookingStateMachine _stateMachine;

  static String selectFields({String? fieldName}) {
    if (fieldName != null) return 'timeline, status, $fieldName';
    return 'timeline, status';
  }

  /// Evaluates handshake without touching the database.
  HandshakeComputation evaluate({
    required String bookingId,
    required String timelineEvent,
    required String nowIso,
    required String authUserId,
    required Map<String, dynamic> booking,
    String? fieldName,
    BookingStatus? newStatus,
    Map<String, dynamic>? additionalUpdates,
  }) {
    // Idempotency guard: skip if the timestamp field is already set
    if (fieldName != null && booking[fieldName] != null) {
      return HandshakeSkip(HandshakeSkipReason.timestampAlreadySet);
    }

    // Safety guard + FSM (only when status column is non-null in snapshot)
    if (booking['status'] != null) {
      final currentStatus = BookingStatus.fromString(booking['status'] as String?);
      if (currentStatus == BookingStatus.completed ||
          currentStatus == BookingStatus.cancelled) {
        return HandshakeSkip(HandshakeSkipReason.terminalBooking);
      }

      if (newStatus != null) {
        if (currentStatus == newStatus) {
          return HandshakeSkip(HandshakeSkipReason.statusAlreadyMatches);
        }

        _stateMachine.ensureTransitionAllowed(currentStatus, newStatus);
      }
    }

    List<dynamic> currentTimeline = booking['timeline'] != null
        ? List<dynamic>.from(booking['timeline'] as List)
        : <dynamic>[];

    currentTimeline.add(<String, dynamic>{
      'event': timelineEvent,
      'timestamp': nowIso,
      'user_id': authUserId,
    });

    final updates = <String, dynamic>{
      'timeline': currentTimeline,
      ...?additionalUpdates,
    };
    
    if (fieldName != null) {
      updates[fieldName] = nowIso;
    }

    if (newStatus != null) {
      updates['status'] = newStatus.toStringValue();
    }

    return HandshakeApply(updates);
  }
}
