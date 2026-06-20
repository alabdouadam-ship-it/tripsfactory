import 'package:tripsfactory/core/demo/demo_data.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/core/utils/result.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/domain/repositories/trip_repository.dart';

/// In-memory [ITripRepository] used in demo mode. Serves seeded trips/locations
/// and treats writes as no-ops so the browse experience works with no backend.
class DemoTripRepository implements ITripRepository {
  @override
  Future<Result<List<Trip>>> searchTrips({
    String? originCity,
    String? destinationCity,
    String? originLocationId,
    String? destLocationId,
    bool isInternal = true,
    String? vehicleType,
    double? minWeight,
    DateTime? date,
    String? originProvince,
    String? destProvince,
    String? city,
    int limit = 20,
    int offset = 0,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    String? currentUserId,
  }) async {
    final trips = DemoData.trips.where((t) {
      final external = Location.isExternalTrip(
        t.originLocation,
        t.destLocation,
      );
      // isInternal=true → home-country routes; false → external routes.
      return isInternal ? !external : external;
    }).toList();
    return Result.success(trips);
  }

  @override
  Future<Result<Map<String, BookingStatus>>> getBookingStatusesForTrips(
    List<String> tripIds,
  ) async {
    return Result.success(<String, BookingStatus>{});
  }

  @override
  Future<Result<Trip>> getTripById(String id) async {
    final trip = DemoData.trips.where((t) => t.id == id).toList();
    if (trip.isEmpty) {
      return Result.failure(TripsFactoryException('Trip not available in demo.'));
    }
    return Result.success(trip.first);
  }

  @override
  Future<Result<void>> createTrip(Map<String, dynamic> tripData) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> cancelTrip(String tripId) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> markTripAsFull(String tripId) async {
    return Result.success(null);
  }

  @override
  Stream<Result<List<Trip>>> watchMyTrips(String driverId) {
    return Stream.value(Result.success(DemoData.myTrips));
  }

  @override
  Future<Result<List<Location>>> getLocations() async {
    return Result.success(DemoData.locations);
  }

  @override
  Stream<Result<Trip>> watchTrip(String id) async* {
    final result = await getTripById(id);
    yield result;
  }
}
