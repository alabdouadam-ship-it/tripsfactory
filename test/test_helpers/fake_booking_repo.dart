import 'package:tripship/core/utils/result.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/bookings/domain/repositories/booking_repository.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'dart:io';

/// Minimal fake for conversion tests: returns fixed booking list and succeeds/fails as configured.
class FakeBookingRepository implements IBookingRepository {
  List<Booking> bookings;
  bool acceptSucceeds;
  bool rejectSucceeds;

  FakeBookingRepository({
    List<Booking>? bookings,
    this.acceptSucceeds = true,
    this.rejectSucceeds = true,
  }) : bookings = bookings ?? [];

  @override
  Future<Result<List<Booking>>> getBookingsForTrip(String tripId) async =>
      Result.success(bookings);

  @override
  Future<Result<Booking?>> getUserBookingForTrip(String tripId) async =>
      Result.success(bookings.isNotEmpty ? bookings.first : null);

  @override
  Stream<Result<List<Booking>>> watchBookingsForTrip(String tripId) =>
      Stream.value(Result.success(bookings));

  @override
  Stream<Result<Booking?>> watchUserBookingForTrip(String tripId) =>
      Stream.value(Result.success(bookings.isNotEmpty ? bookings.first : null));

  @override
  Future<Result<void>> acceptBooking(String bookingId) async => acceptSucceeds
      ? Result.success(null)
      : Result.failure(TripShipException.withKey('test', 'fail', null));

  @override
  Future<Result<void>> rejectBooking(String bookingId) async => rejectSucceeds
      ? Result.success(null)
      : Result.failure(TripShipException.withKey('test', 'fail', null));

  @override
  Future<Result<void>> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) async => Result.success(null);

  @override
  Future<Result<void>> markGoodsHandedOver(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markPaymentSent(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> confirmGoodsReceivedByClient(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> confirmGoodsReceived(
    String bookingId, {
    File? pickupPhoto,
  }) async => Result.success(null);

  @override
  Future<Result<void>> confirmPaymentReceived(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markGoodsDelivered(
    String bookingId, {
    File? deliveryPhoto,
  }) async => Result.success(null);

  @override
  Future<Result<void>> markGoodsDeliveredWithCode(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  }) async => Result.success(null);

  @override
  Future<Result<void>> createDirectBooking({
    required String userId,
    required String driverId,
    required String tripId,
  }) async => Result.success(null);

  @override
  Future<Result<String>> createBookingWithFirstMessage({
    required String tripId,
    required String driverId,
    required String firstMessageContent,
    String? type,
    Map<String, dynamic>? metadata,
  }) async => Result.success('fake_booking_id');

  @override
  Future<Result<BookingStatus?>> getBookingStatus(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<String?>> getRecipientRoleForUser(
    String bookingId,
    String userId,
  ) async => Result.success(null);

  @override
  Stream<Result<List<Booking>>> watchMyRequests() =>
      Stream.value(Result.success(bookings));
}
