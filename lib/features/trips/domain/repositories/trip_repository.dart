import 'package:tripship/core/utils/result.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/core/enums/app_enums.dart';

abstract class ITripRepository {
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
  });

  Future<Result<Map<String, BookingStatus>>> getBookingStatusesForTrips(
    List<String> tripIds,
  );

  Future<Result<Trip>> getTripById(String id);

  Future<Result<void>> createTrip(Map<String, dynamic> tripData);

  Future<Result<void>> cancelTrip(String tripId);

  Future<Result<void>> markTripAsFull(String tripId);

  Stream<Result<List<Trip>>> watchMyTrips(String driverId);

  Future<Result<List<Location>>> getLocations();

  Stream<Result<Trip>> watchTrip(String id);
}
