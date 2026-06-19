import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';

/// Client-side booking FSM validation (used by [HandshakeEngine]).
class BookingStateMachine {
  const BookingStateMachine();

  /// Throws [TripShipException] with key `illegal_transition` when disallowed.
  void ensureTransitionAllowed(BookingStatus current, BookingStatus next) {
    if (!current.canTransitionTo(next)) {
      throw TripShipException.withKey(
        'illegal_transition',
        'Cannot transition from ${current.toStringValue()} to ${next.toStringValue()}.',
      );
    }
  }
}
