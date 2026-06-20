import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/enums/app_enums.dart';

void main() {
  group('BookingStatus FSM (Handshake Guards)', () {
    test('pending transitions', () {
      final status = BookingStatus.pending;
      expect(status.canTransitionTo(BookingStatus.accepted), isTrue);
      expect(status.canTransitionTo(BookingStatus.rejected), isTrue);
      expect(status.canTransitionTo(BookingStatus.cancelled), isTrue);

      // Invalid transitions
      expect(status.canTransitionTo(BookingStatus.inTransit), isFalse);
      expect(status.canTransitionTo(BookingStatus.completed), isFalse);
      expect(status.canTransitionTo(BookingStatus.delivered), isFalse);
    });

    test('in_communication transitions (3.27 implementation detail)', () {
      final s = BookingStatus.inCommunication;
      expect(s.canTransitionTo(BookingStatus.pending), isTrue);
      expect(s.canTransitionTo(BookingStatus.cancelled), isTrue);
      expect(s.canTransitionTo(BookingStatus.accepted), isFalse);
      expect(s.canTransitionTo(BookingStatus.inTransit), isFalse);
    });

    test('accepted transitions', () {
      final status = BookingStatus.accepted;
      expect(status.canTransitionTo(BookingStatus.inTransit), isTrue);
      expect(status.canTransitionTo(BookingStatus.cancelled), isTrue);

      // Invalid transitions
      expect(status.canTransitionTo(BookingStatus.pending), isFalse);
      expect(status.canTransitionTo(BookingStatus.delivered), isFalse);
    });

    test('in_transit transitions', () {
      final status = BookingStatus.inTransit;
      // Driver can deliver, or immediate completion via OTP
      expect(status.canTransitionTo(BookingStatus.delivered), isTrue);
      expect(status.canTransitionTo(BookingStatus.completed), isTrue);

      // Invalid transitions (cannot cancel once in transit)
      expect(status.canTransitionTo(BookingStatus.cancelled), isFalse);
      expect(status.canTransitionTo(BookingStatus.pending), isFalse);
    });

    test('delivered transitions', () {
      final status = BookingStatus.delivered;
      expect(status.canTransitionTo(BookingStatus.completed), isTrue);

      // Invalid
      expect(status.canTransitionTo(BookingStatus.cancelled), isFalse);
    });

    test('terminal states cannot transition further', () {
      expect(
        BookingStatus.completed.canTransitionTo(BookingStatus.cancelled),
        isFalse,
      );
      expect(
        BookingStatus.cancelled.canTransitionTo(BookingStatus.pending),
        isFalse,
      );
      expect(
        BookingStatus.rejected.canTransitionTo(BookingStatus.accepted),
        isFalse,
      );
    });
  });
}
