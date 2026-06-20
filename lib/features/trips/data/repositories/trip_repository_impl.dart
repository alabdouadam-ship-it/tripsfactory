import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/core/utils/result.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/data/trip_service.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/features/trips/domain/repositories/trip_repository.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/models/offline_action.dart';
import 'package:tripsfactory/core/services/offline_sync_service.dart';
import 'package:tripsfactory/core/utils/network_utils.dart';

final tripRepositoryProvider = Provider<ITripRepository>((ref) {
  final service = ref.watch(tripServiceProvider);
  final offlineService = ref.watch(offlineSyncServiceProvider);
  return TripRepository(service, offlineService);
});

class TripRepository implements ITripRepository {
  final TripService _service;
  final OfflineSyncService _offlineService;

  TripRepository(this._service, this._offlineService);

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
    try {
      final trips = await _service.searchTrips(
        originCity: originCity,
        destinationCity: destinationCity,
        originLocationId: originLocationId,
        destLocationId: destLocationId,
        isInternal: isInternal,
        vehicleType: vehicleType,
        minWeight: minWeight,
        date: date,
        originProvince: originProvince,
        destProvince: destProvince,
        city: city,
        limit: limit,
        offset: offset,
        currentUserId: currentUserId,
      );
      return Result.success(trips);
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<Map<String, BookingStatus>>> getBookingStatusesForTrips(
    List<String> tripIds,
  ) async {
    try {
      final statuses = await _service.getBookingStatusesForTrips(tripIds);
      return Result.success(statuses);
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<Trip>> getTripById(String id) async {
    try {
      final trip = await _service.getTripById(id);
      if (trip == null) {
        return Result.failure(
          TripsFactoryException.withKey('trip_not_found', 'Trip not found.'),
        );
      }
      return Result.success(trip);
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  Future<Result<void>> _executeWithOfflineSupport({
    required String actionType,
    required Map<String, dynamic> payload,
    required Future<void> Function() onlineAction,
  }) async {
    try {
      final isOnline = await NetworkUtils.isOnline();
      if (!isOnline) {
        await _offlineService.enqueueAction(
          OfflineAction(type: actionType, payload: payload),
        );
        return Result.success(null);
      }
      await onlineAction();
      return Result.success(null);
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<void>> createTrip(Map<String, dynamic> tripData) {
    return _executeWithOfflineSupport(
      actionType: 'create_trip',
      payload: tripData,
      onlineAction: () => _service.createTrip(
        driverId: tripData['driverId'],
        originLocationId: tripData['originLocationId'],
        destLocationId: tripData['destLocationId'],
        departureTime: tripData['departureTime'],
        maxWeight: tripData['maxWeight'],
        suggestedFlatPrice: tripData['suggestedFlatPrice'],
        notes: tripData['notes'],
      ),
    );
  }

  @override
  Future<Result<void>> cancelTrip(String tripId) {
    return _executeWithOfflineSupport(
      actionType: 'cancel_trip',
      payload: {'tripId': tripId},
      onlineAction: () => _service.cancelTrip(tripId),
    );
  }

  @override
  Future<Result<void>> markTripAsFull(String tripId) async {
    try {
      await _service.markTripAsFull(tripId);
      return Result.success(null);
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Stream<Result<List<Trip>>> watchMyTrips(String driverId) {
    return _service
        .watchMyTrips(driverId)
        .map((trips) {
          return Result.success(trips);
        })
        .handleError((error) {
          if (error is TripsFactoryException) {
            return Result<List<Trip>>.failure(error);
          }
          return Result<List<Trip>>.failure(
            TripsFactoryException.withKey('unknown_error', error.toString(), error),
          );
        });
  }

  @override
  Future<Result<List<Location>>> getLocations() async {
    try {
      final locations = await _service.getLocations();
      return Result.success(locations);
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Stream<Result<Trip>> watchTrip(String id) {
    return _service
        .watchTrip(id)
        .map((trip) {
          return Result.success(trip);
        })
        .handleError((error) {
          if (error is TripsFactoryException) {
            return Result<Trip>.failure(error);
          }
          return Result<Trip>.failure(
            TripsFactoryException.withKey('unknown_error', error.toString(), error),
          );
        });
  }
}
