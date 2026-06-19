import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/trips/data/trip_model.dart';

class TripDetailsState {
  final Trip? trip;
  final List<Booking> bookings;
  final Booking? userBooking;
  final Set<String> ratedBookingIds;
  final bool isLoading;
  final bool isLoadingBookings;
  final String? error;

  TripDetailsState({
    this.trip,
    this.bookings = const [],
    this.userBooking,
    this.ratedBookingIds = const {},
    this.isLoading = false,
    this.isLoadingBookings = false,
    this.error,
  });

  TripDetailsState copyWith({
    Trip? trip,
    List<Booking>? bookings,
    Booking? userBooking,
    Set<String>? ratedBookingIds,
    bool? isLoading,
    bool? isLoadingBookings,
    String? Function()? error,
  }) {
    return TripDetailsState(
      trip: trip ?? this.trip,
      bookings: bookings ?? this.bookings,
      userBooking: userBooking ?? this.userBooking,
      ratedBookingIds: ratedBookingIds ?? this.ratedBookingIds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      error: error != null ? error() : this.error,
    );
  }
}
