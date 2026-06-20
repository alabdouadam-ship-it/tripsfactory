import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/trip_status_sync_rules.dart';

void main() {
  group('tripStatusAllowsAutoMarkFull (3.19 gate)', () {
    test('allows when trip is booked', () {
      expect(tripStatusAllowsAutoMarkFull(TripStatus.booked), isTrue);
    });

    test('allows when trip is available', () {
      expect(tripStatusAllowsAutoMarkFull(TripStatus.available), isTrue);
    });

    test('disallows when already full, completed, or cancelled', () {
      expect(tripStatusAllowsAutoMarkFull(TripStatus.full), isFalse);
      expect(tripStatusAllowsAutoMarkFull(TripStatus.completed), isFalse);
      expect(tripStatusAllowsAutoMarkFull(TripStatus.cancelled), isFalse);
    });
  });

  group('bookingsAllowTripComplete (3.20)', () {
    test('true when all terminal and at least one completed', () {
      expect(
        bookingsAllowTripComplete([
          BookingStatus.completed.toStringValue(),
          BookingStatus.rejected.toStringValue(),
        ]),
        isTrue,
      );
      expect(
        bookingsAllowTripComplete([
          BookingStatus.completed.toStringValue(),
          BookingStatus.cancelled.toStringValue(),
        ]),
        isTrue,
      );
    });

    test('true when completed plus ignored in_communication only', () {
      expect(
        bookingsAllowTripComplete([
          BookingStatus.completed.toStringValue(),
          BookingStatus.inCommunication.toStringValue(),
        ]),
        isTrue,
      );
    });

    test('false when pending or accepted remains', () {
      expect(
        bookingsAllowTripComplete([
          BookingStatus.completed.toStringValue(),
          BookingStatus.pending.toStringValue(),
        ]),
        isFalse,
      );
      expect(
        bookingsAllowTripComplete([
          BookingStatus.accepted.toStringValue(),
          BookingStatus.rejected.toStringValue(),
        ]),
        isFalse,
      );
    });

    test('false when all terminal but none completed', () {
      expect(
        bookingsAllowTripComplete([
          BookingStatus.rejected.toStringValue(),
          BookingStatus.cancelled.toStringValue(),
        ]),
        isFalse,
      );
    });

    test('false when empty', () {
      expect(bookingsAllowTripComplete([]), isFalse);
    });
  });
}
