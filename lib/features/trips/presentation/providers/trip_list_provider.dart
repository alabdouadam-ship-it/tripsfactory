import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/home/presentation/providers/home_filter_provider.dart';
import 'package:tripship/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/core/services/cache_service.dart';
import 'package:tripship/core/enums/app_enums.dart';

part 'trip_list_provider.freezed.dart';

@freezed
abstract class TripListState with _$TripListState {
  const factory TripListState({
    @Default([]) List<Trip> trips,
    @Default({}) Map<String, BookingStatus> bookingStatuses,
    @Default(0) int offset,
    @Default(true) bool hasMore,
    @Default(false) bool showCachedBanner,
    @Default(false) bool isInitialLoad,
  }) = _TripListState;
}

class TripListFilter {
  final bool isInternal;
  final HomeFilterState filterState;

  TripListFilter({required this.isInternal, required this.filterState});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripListFilter &&
          runtimeType == other.runtimeType &&
          isInternal == other.isInternal &&
          filterState == other.filterState;

  @override
  int get hashCode => isInternal.hashCode ^ filterState.hashCode;
}

class TripListNotifier
    extends FamilyAsyncNotifier<TripListState, TripListFilter> {
  static const int _limit = 20;

  @override
  Future<TripListState> build(TripListFilter arg) async {
    return _loadInitialTrips();
  }

  String get _cacheKey {
    final filterState = arg.filterState;
    return '${arg.isInternal}_${filterState.vehicleType ?? ""}_${filterState.originCity ?? ""}_${filterState.destinationCity ?? ""}_${filterState.originLocationId ?? ""}_${filterState.destLocationId ?? ""}_${filterState.originProvince ?? ""}_${filterState.destProvince ?? ""}';
  }

  Future<TripListState> _loadInitialTrips() async {
    try {
      final currentUserId = ref.read(authServiceProvider).currentUser?.id;
      final filterState = arg.filterState;

      final result = await ref
          .read(tripRepositoryProvider)
          .searchTrips(
            isInternal: arg.isInternal,
            currentUserId: currentUserId,
            vehicleType: filterState.vehicleType,
            originCity: filterState.originCity,
            destinationCity: filterState.destinationCity,
            originLocationId: filterState.originLocationId,
            destLocationId: filterState.destLocationId,
            minWeight: filterState.minWeight,
            date: filterState.date,
            originProvince: filterState.originProvince,
            destProvince: filterState.destProvince,
            limit: _limit,
            offset: 0,
          );

      final trips = result.fold((trips) => trips, (error) => throw error);

      await ref.read(cacheServiceProvider).cacheTrips(trips, _cacheKey);
      final bookingStatuses = await _batchFetchStatuses(trips);

      return TripListState(
        trips: trips,
        bookingStatuses: bookingStatuses,
        offset: trips.length,
        hasMore: trips.length == _limit,
        showCachedBanner: false,
      );
    } catch (e) {
      final cached = await ref
          .read(cacheServiceProvider)
          .getCachedTrips(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final bookingStatuses = await _batchFetchStatuses(cached);
        return TripListState(
          trips: cached,
          bookingStatuses: bookingStatuses,
          offset: cached.length,
          hasMore: false,
          showCachedBanner: true,
        );
      }
      rethrow;
    }
  }

  Future<void> loadMoreTrips() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore || state.isLoading) {
      return;
    }

    try {
      final currentUserId = ref.read(authServiceProvider).currentUser?.id;
      final filterState = arg.filterState;

      final result = await ref
          .read(tripRepositoryProvider)
          .searchTrips(
            isInternal: arg.isInternal,
            currentUserId: currentUserId,
            vehicleType: filterState.vehicleType,
            originCity: filterState.originCity,
            destinationCity: filterState.destinationCity,
            originLocationId: filterState.originLocationId,
            destLocationId: filterState.destLocationId,
            minWeight: filterState.minWeight,
            date: filterState.date,
            originProvince: filterState.originProvince,
            destProvince: filterState.destProvince,
            limit: _limit,
            offset: currentState.offset,
          );

      final newTrips = result.fold((trips) => trips, (error) => throw error);
      final newStatuses = await _batchFetchStatuses(newTrips);

      state = AsyncData(
        currentState.copyWith(
          trips: [...currentState.trips, ...newTrips],
          bookingStatuses: {...currentState.bookingStatuses, ...newStatuses},
          offset: currentState.offset + newTrips.length,
          hasMore: newTrips.length == _limit,
        ),
      );
    } catch (e) {
      // Do nothing on pagination fail, keep current state so the user isn't wiped out
    }
  }

  Future<Map<String, BookingStatus>> _batchFetchStatuses(
    List<Trip> trips,
  ) async {
    if (trips.isEmpty) return {};

    try {
      final tripIds = trips.map((t) => t.id).toList();
      final result = await ref
          .read(tripRepositoryProvider)
          .getBookingStatusesForTrips(tripIds);
      return result.fold((statuses) => statuses, (error) => {});
    } catch (e) {
      return {};
    }
  }

  Future<void> refreshBookingStatusForTrip(Trip trip) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final newStatuses = await _batchFetchStatuses([trip]);
    final hasInteractedValue = newStatuses.containsKey(trip.id);

    if (hasInteractedValue) {
      // If user interacted, remove from discovery list immediately
      state = AsyncValue.data(
        currentState.copyWith(
          trips: currentState.trips.where((t) => t.id != trip.id).toList(),
          bookingStatuses: Map.from(currentState.bookingStatuses)
            ..remove(trip.id),
        ),
      );
    } else {
      state = AsyncValue.data(
        currentState.copyWith(
          bookingStatuses: {...currentState.bookingStatuses, ...newStatuses},
        ),
      );
    }
  }
}

final tripListProvider =
    AsyncNotifierProviderFamily<
      TripListNotifier,
      TripListState,
      TripListFilter
    >(TripListNotifier.new);
