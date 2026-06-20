import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

/// Client-side booking FSM validation (used by [HandshakeEngine]).
class BookingStateMachine {
  const BookingStateMachine();

  /// Throws [TripsFactoryException] with key `illegal_transition` when disallowed.
  void ensureTransitionAllowed(BookingStatus current, BookingStatus next) {
    if (!current.canTransitionTo(next)) {
      throw TripsFactoryException.withKey(
        'illegal_transition',
        'Cannot transition from ${current.toStringValue()} to ${next.toStringValue()}.',
      );
    }
  }
}
