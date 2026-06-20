import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripsfactory/features/ratings/data/repositories/rating_repository_impl.dart';
import 'package:tripsfactory/features/safety/data/safety_service.dart' as tripsfactory; // Need alias since we use it directly
import 'package:tripsfactory/core/utils/result.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/utils/logger.dart';

import 'trip_details_state.dart';

class TripDetailsController extends FamilyNotifier<TripDetailsState, String> {
  StreamSubscription? _tripSubscription;
  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _userBookingSubscription;

  @override
  TripDetailsState build(String arg) {
    ref.onDispose(() {
      _tripSubscription?.cancel();
      _bookingsSubscription?.cancel();
      _userBookingSubscription?.cancel();
    });
    return TripDetailsState();
  }

  Future<void> init(Trip? trip, String? tripId) async {
    if (trip != null) {
      state = state.copyWith(trip: trip, isLoading: false);
      _loadInitialData();
      // Background refresh only when the passed trip may have partial data
      // (e.g. no vehicle join from a list query). Skip if vehicles are present.
      final hasVehicles =
          trip.driver != null && (trip.driver!.vehicles.isNotEmpty);
      if (!hasVehicles) {
        final result = await ref
            .read(tripRepositoryProvider)
            .getTripById(trip.id);
        result.fold(
          (updated) => state = state.copyWith(trip: updated),
          (_) => null,
        );
      }
    } else if (tripId != null) {
      await fetchTrip(tripId);
    }
  }

  Future<void> fetchTrip(String id) async {
    state = state.copyWith(isLoading: true, error: () => null);
    final result = await ref.read(tripRepositoryProvider).getTripById(id);

    result.fold(
      (trip) {
        state = state.copyWith(trip: trip, isLoading: false);
        _loadInitialData();
      },
      (error) => state = state.copyWith(
        isLoading: false,
        error: () => error.userMessage,
      ),
    );
  }

  void _loadInitialData() {
    _subscribeToTripUpdates();
    _subscribeToBookingsUpdates();
    _subscribeToUserBookingUpdates();
  }

  void _subscribeToTripUpdates() {
    if (state.trip == null) return;
    _tripSubscription?.cancel();
    _tripSubscription = ref
        .read(tripRepositoryProvider)
        .watchTrip(state.trip!.id)
        .listen((result) {
          result.fold(
            (updated) => state = state.copyWith(trip: updated),
            (_) => null,
          );
        });
  }

  void _subscribeToBookingsUpdates() {
    if (state.trip == null) return;
    final currentUser = ref.read(authServiceProvider).currentUser;
    final isDriver = currentUser?.id == state.trip!.driverId;

    if (!isDriver) {
      state = state.copyWith(bookings: const [], isLoadingBookings: false);
      return;
    }

    state = state.copyWith(isLoadingBookings: true);
    _bookingsSubscription?.cancel();
    _bookingsSubscription = ref
        .read(bookingRepositoryProvider)
        .watchBookingsForTrip(state.trip!.id)
        .listen((result) async {
          result.fold(
            (fetchedBookings) async {
              state = state.copyWith(
                bookings: fetchedBookings,
                isLoadingBookings: false,
              );
              _refreshRatedBookingIds();
            },
            (error) => state = state.copyWith(
              isLoadingBookings: false,
              error: () => error.userMessage,
            ),
          );
        });
  }

  void _subscribeToUserBookingUpdates() {
    if (state.trip == null) return;
    _userBookingSubscription?.cancel();
    _userBookingSubscription = ref
        .read(bookingRepositoryProvider)
        .watchUserBookingForTrip(state.trip!.id)
        .listen((result) {
          result.fold(
            (booking) {
              state = state.copyWith(userBooking: booking);
              _refreshRatedBookingIds();
            },
            (error) => StructuredLogger.error(
              'TripDetailsController',
              'Error loading user booking: ${error.userMessage}',
              error,
            ),
          );
        });
  }

  Future<void> _refreshRatedBookingIds() async {
    final completedBookings = [
      if (state.userBooking != null &&
          state.userBooking!.status == BookingStatus.completed)
        state.userBooking!,
      ...state.bookings.where((b) => b.status == BookingStatus.completed),
    ];

    if (completedBookings.isEmpty) {
      state = state.copyWith(ratedBookingIds: const {});
      return;
    }

    final completedIds = completedBookings.map((b) => b.id).toList();
    final ratingResult = await ref
        .read(ratingRepositoryProvider)
        .getRatedBookingIds(completedIds);

    final ratedIds = ratingResult.fold((ids) => ids, (_) => <String>{});

    state = state.copyWith(ratedBookingIds: ratedIds);
  }

  Future<void> performAction(Future<Result<void>> Function() action) async {
    state = state.copyWith(isLoading: true);
    final result = await action();

    result.fold(
      (_) async {
        // State updates via subscriptions eventually, but we trigger a manual
        // local refresh here for immediate optimistic feedback.
        if (state.trip != null) {
          // Refresh trip and bookings specifically to force local state change
          // before the realtime throttle/latency kicks in.
          unawaited(fetchTrip(state.trip!.id));
          unawaited(loadBookings());
          unawaited(loadUserBooking());
        }
        state = state.copyWith(isLoading: false);
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: () => error.userMessage,
        );
      },
    );
  }

  // Action Methods
  Future<void> markHandover(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).markGoodsHandedOver(bookingId),
  );

  Future<void> markPayment(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).markPaymentSent(bookingId),
  );

  Future<void> confirmReceipt(String bookingId) => performAction(
    () => ref
        .read(bookingRepositoryProvider)
        .confirmGoodsReceivedByClient(bookingId),
  );

  Future<void> confirmCollection(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).confirmGoodsReceived(bookingId),
  );

  Future<void> confirmPaymentReceived(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).confirmPaymentReceived(bookingId),
  );

  Future<void> markDelivered(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).markGoodsDelivered(bookingId),
  );

  Future<void> markDeliveredWithOTP(String bookingId, String code) =>
      performAction(
        () => ref
            .read(bookingRepositoryProvider)
            .markGoodsDeliveredWithCode(bookingId, code),
      );

  Future<void> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) => performAction(
    () => ref
        .read(bookingRepositoryProvider)
        .cancelBooking(bookingId, isDriver: isDriver, reason: reason),
  );

  Future<void> acceptBooking(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).acceptBooking(bookingId),
  );

  Future<void> rejectBooking(String bookingId) => performAction(
    () => ref.read(bookingRepositoryProvider).rejectBooking(bookingId),
  );

  Future<void> markTripAsFull() => performAction(() async {
    if (state.trip == null) {
      return Result.failure(
        TripsFactoryException.withKey(
          'no_trip',
          'No trip selected',
          'No trip in state',
        ),
      );
    }
    return ref.read(tripRepositoryProvider).markTripAsFull(state.trip!.id);
  });

  Future<void> cancelTrip() => performAction(() {
    if (state.trip == null) {
      return Future.value(
        Result.failure(TripsFactoryException.withKey('no_trip', 'No trip selected')),
      );
    }
    return ref.read(tripRepositoryProvider).cancelTrip(state.trip!.id);
  });

  Future<void> loadBookings() async {
    // Re-subscribe to force an immediate refresh
    _subscribeToBookingsUpdates();
  }

  Future<void> loadUserBooking() async {
    // Re-subscribe to force an immediate refresh
    _subscribeToUserBookingUpdates();
  }

  Future<void> contactTraveler() async {
    if (state.trip == null) return;
    state = state.copyWith(isLoading: true);

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final isBlocked = await ref
          .read(tripsfactory.safetyServiceProvider) // Add import for safetyServiceProvider
          .isUserBlocked(state.trip!.driverId);
          
      if (isBlocked) {
         state = state.copyWith(
           isLoading: false, 
           error: () => 'cannot_book_blocked',
         );
         return;
      }
    } catch (e) {
      // Ignore block check failure and proceed assuming not blocked
    }

    final result = await ref
        .read(bookingRepositoryProvider)
        .createDirectBooking(
          userId: currentUser.id,
          driverId: state.trip!.driverId,
          tripId: state.trip!.id,
        );

    result.fold(
      (_) async {
        // State updates via realtime subscriptions automatically
        state = state.copyWith(isLoading: false);
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: () => error.userMessage,
        );
      },
    );
  }

  void addRatedBookingId(String id) {
    state = state.copyWith(ratedBookingIds: {...state.ratedBookingIds, id});
  }
}

final tripDetailsControllerProvider =
    NotifierProvider.family<TripDetailsController, TripDetailsState, String>(
      TripDetailsController.new,
    );
