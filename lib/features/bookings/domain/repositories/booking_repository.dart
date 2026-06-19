import 'dart:io';
import 'package:tripship/core/utils/result.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';

abstract class IBookingRepository {
  Future<Result<List<Booking>>> getBookingsForTrip(String tripId);
  Future<Result<Booking?>> getUserBookingForTrip(String tripId);
  Future<Result<void>> acceptBooking(String bookingId);
  Future<Result<void>> rejectBooking(String bookingId);
  Future<Result<void>> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  });
  Future<Result<void>> markGoodsHandedOver(String bookingId);
  Future<Result<void>> markPaymentSent(String bookingId);
  Future<Result<void>> confirmGoodsReceivedByClient(String bookingId);
  Future<Result<void>> confirmGoodsReceived(
    String bookingId, {
    File? pickupPhoto,
  });
  Future<Result<void>> confirmPaymentReceived(String bookingId);
  Future<Result<void>> markGoodsDelivered(
    String bookingId, {
    File? deliveryPhoto,
  });
  Future<Result<void>> markGoodsDeliveredWithCode(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  });
  Future<Result<void>> createDirectBooking({
    required String userId,
    required String driverId,
    required String tripId,
  });
  Future<Result<String>> createBookingWithFirstMessage({
    required String tripId,
    required String driverId,
    required String firstMessageContent,
    String? type,
    Map<String, dynamic>? metadata,
  });
  Future<Result<BookingStatus?>> getBookingStatus(String bookingId);
  Future<Result<String?>> getRecipientRoleForUser(
    String bookingId,
    String userId,
  );

  Stream<Result<List<Booking>>> watchBookingsForTrip(String tripId);
  Stream<Result<Booking?>> watchUserBookingForTrip(String tripId);
  Stream<Result<List<Booking>>> watchMyRequests();
}
