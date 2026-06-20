import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/booking_state_machine.dart';

void main() {
  const sm = BookingStateMachine();

  test('ensureTransitionAllowed throws for illegal move', () {
    expect(
      () => sm.ensureTransitionAllowed(BookingStatus.pending, BookingStatus.delivered),
      throwsA(
          predicate<TripsFactoryException>((e) => e.messageKey == 'illegal_transition')),
    );
  });

  test('ensureTransitionAllowed allows legal move', () {
    expect(
      () => sm.ensureTransitionAllowed(BookingStatus.pending, BookingStatus.accepted),
      returnsNormally,
    );
  });
}
