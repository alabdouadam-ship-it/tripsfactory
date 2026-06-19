import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/features/bookings/data/lifecycle/booking_state_machine.dart';

void main() {
  const sm = BookingStateMachine();

  test('ensureTransitionAllowed throws for illegal move', () {
    expect(
      () => sm.ensureTransitionAllowed(BookingStatus.pending, BookingStatus.delivered),
      throwsA(
          predicate<TripShipException>((e) => e.messageKey == 'illegal_transition')),
    );
  });

  test('ensureTransitionAllowed allows legal move', () {
    expect(
      () => sm.ensureTransitionAllowed(BookingStatus.pending, BookingStatus.accepted),
      returnsNormally,
    );
  });
}
