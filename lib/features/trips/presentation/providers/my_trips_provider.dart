import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';

enum TripFilter { all, available, full, completed, cancelled }

final myTripsFilterProvider = StateProvider<TripFilter>(
  (ref) => TripFilter.all,
);

class MyTripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  FutureOr<List<Trip>> build() {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return [];

    // Transform stream into AsyncValue via the Notifier
    final stream = ref.read(tripRepositoryProvider).watchMyTrips(user.id);

    // Listen to the stream and update the state
    final sub = stream.listen((result) {
      result.fold(
        (trips) => state = AsyncData(trips),
        (error) => state = AsyncError(error, StackTrace.current),
      );
    });

    // Cleanup when provider is disposed
    ref.onDispose(() => sub.cancel());

    // Initially grab the first value manually or assume loading
    return stream.first.then((res) => res.fold((t) => t, (e) => throw e));
  }

  void cancelTrip(String tripId) async {
    try {
      final result = await ref.read(tripRepositoryProvider).cancelTrip(tripId);
      result.fold((_) {}, (error) => throw error);
    } catch (e) {
      // Allow caller to catch if needed or handle globally
      rethrow;
    }
  }
}

final myTripsProvider = AsyncNotifierProvider<MyTripsNotifier, List<Trip>>(
  MyTripsNotifier.new,
);

final filteredMyTripsProvider = Provider<AsyncValue<List<Trip>>>((ref) {
  final tripsAsync = ref.watch(myTripsProvider);
  final filter = ref.watch(myTripsFilterProvider);

  return tripsAsync.whenData((trips) {
    var filtered = trips.where((trip) {
      final s = trip.status;
      switch (filter) {
        case TripFilter.all:
          return true;
        case TripFilter.available:
          return s == TripStatus.available ||
              s == TripStatus.inCommunication ||
              s == TripStatus.pendingConfirmation ||
              s == TripStatus.booked ||
              s == TripStatus.inTransit;
        case TripFilter.full:
          return s == TripStatus.full;
        case TripFilter.completed:
          return s == TripStatus.completed;
        case TripFilter.cancelled:
          return s == TripStatus.cancelled;
      }
    }).toList();

    // Sort: active trips first, then completed/cancelled; within each group by date desc
    filtered.sort((a, b) {
      final aTerminal =
          a.status == TripStatus.completed || a.status == TripStatus.cancelled;
      final bTerminal =
          b.status == TripStatus.completed || b.status == TripStatus.cancelled;
      if (aTerminal != bTerminal) return aTerminal ? 1 : -1;
      return b.departureTime.compareTo(a.departureTime);
    });

    return filtered;
  });
});
