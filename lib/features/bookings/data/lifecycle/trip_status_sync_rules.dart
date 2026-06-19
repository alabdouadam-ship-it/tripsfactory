import 'package:tripship/core/enums/app_enums.dart';

/// Pure rules for [TripStatusSyncService] (unit-tested; keeps DB I/O thin).
bool tripStatusAllowsAutoMarkFull(TripStatus current) {
  return current != TripStatus.full &&
      current != TripStatus.completed &&
      current != TripStatus.cancelled;
}

/// True when every booking is terminal (completed/cancelled/rejected) or ignored
/// (`in_communication`), and at least one booking is `completed`.
/// [statusStrings] are DB `status` column values (snake_case strings).
bool bookingsAllowTripComplete(Iterable<String?> statusStrings) {
  final terminal = {
    BookingStatus.completed.toStringValue(),
    BookingStatus.cancelled.toStringValue(),
    BookingStatus.rejected.toStringValue(),
  };
  final ignoredStatus = BookingStatus.inCommunication.toStringValue();

  var hasPendingOrActive = false;
  var hasCompleted = false;

  for (final status in statusStrings) {
    if (status == null) continue;

    if (terminal.contains(status)) {
      if (status == BookingStatus.completed.toStringValue()) {
        hasCompleted = true;
      }
    } else if (status != ignoredStatus) {
      hasPendingOrActive = true;
      break;
    }
  }

  return !hasPendingOrActive && hasCompleted;
}
