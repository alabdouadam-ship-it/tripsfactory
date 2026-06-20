import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';

/// Minimal trip for conversion tests (driver view with bookings).
Trip tripFixture() {
  return Trip(
    id: 'trip-fixture-1',
    driverId: 'driver-1',
    originLocationId: 'origin-1',
    destLocationId: 'dest-1',
    departureTime: DateTime(2025, 1, 15, 10, 0),
    status: TripStatus.booked,
    createdAt: DateTime(2025, 1, 1),
  );
}
