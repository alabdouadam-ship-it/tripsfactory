import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/utils/result.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/bookings/data/booking_service.dart';
import 'package:tripship/features/bookings/data/booking_lifecycle_manager.dart';
import 'package:tripship/features/bookings/domain/repositories/booking_repository.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/models/offline_action.dart';
import 'package:tripship/core/services/offline_sync_service.dart';
import 'package:tripship/core/utils/network_utils.dart';

final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  final service = ref.watch(bookingServiceProvider);
  final lifecycle = ref.watch(bookingLifecycleManagerProvider);
  final offlineService = ref.watch(offlineSyncServiceProvider);
  return BookingRepository(service, lifecycle, offlineService);
});

class BookingRepository implements IBookingRepository {
  final BookingService _service;
  final BookingLifecycleManager _lifecycle;
  final OfflineSyncService _offlineService;

  BookingRepository(this._service, this._lifecycle, this._offlineService);

  @override
  Future<Result<List<Booking>>> getBookingsForTrip(String tripId) async {
    try {
      final bookings = await _service.getBookingsForTrip(tripId);
      return Result.success(bookings);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<Booking?>> getUserBookingForTrip(String tripId) async {
    try {
      final booking = await _service.getUserBookingForTrip(tripId);
      return Result.success(booking);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Stream<Result<List<Booking>>> watchBookingsForTrip(String tripId) {
    return _service
        .watchBookingsForTrip(tripId)
        .map((bookings) {
          return Result.success(bookings);
        })
        .handleError((error) {
          if (error is TripShipException) {
            return Result<List<Booking>>.failure(error);
          }
          return Result<List<Booking>>.failure(
            TripShipException.withKey('unknown_error', error.toString(), error),
          );
        });
  }

  @override
  Stream<Result<Booking?>> watchUserBookingForTrip(String tripId) {
    return _service
        .watchUserBookingForTrip(tripId)
        .map((booking) {
          return Result.success(booking);
        })
        .handleError((error) {
          if (error is TripShipException) {
            return Result<Booking?>.failure(error);
          }
          return Result<Booking?>.failure(
            TripShipException.withKey('unknown_error', error.toString(), error),
          );
        });
  }

  @override
  Stream<Result<List<Booking>>> watchMyRequests() {
    return _service
        .watchMyRequests()
        .map((bookings) {
          return Result.success(bookings);
        })
        .handleError((error) {
          if (error is TripShipException) {
            return Result<List<Booking>>.failure(error);
          }
          return Result<List<Booking>>.failure(
            TripShipException.withKey('unknown_error', error.toString(), error),
          );
        });
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
      try {
        await onlineAction();
        return Result.success(null);
      } catch (e) {
        // If it's a network error, even if isOnline was true, enqueue for offline retry
        if (_isNetworkError(e)) {
          await _offlineService.enqueueAction(
            OfflineAction(type: actionType, payload: payload),
          );
          return Result.success(null);
        }
        rethrow;
      }
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException) return true;
    if (error is TripShipException) {
      final debug = error.debugInfo;
      if (debug != null) return _isNetworkError(debug);
    }
    final errStr = error.toString().toLowerCase();
    return errStr.contains('socketexception') ||
        errStr.contains('timeout') ||
        errStr.contains('connection failed') ||
        errStr.contains('network_error');
  }

  @override
  Future<Result<void>> acceptBooking(String bookingId) {
    return _executeWithOfflineSupport(
      actionType: 'accept_booking',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.acceptBooking(bookingId),
    );
  }

  @override
  Future<Result<void>> rejectBooking(String bookingId) {
    return _executeWithOfflineSupport(
      actionType: 'reject_booking',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.rejectBooking(bookingId),
    );
  }

  @override
  Future<Result<void>> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) {
    return _executeWithOfflineSupport(
      actionType: 'cancel_booking',
      payload: {'bookingId': bookingId, 'isDriver': isDriver, 'reason': reason},
      onlineAction: () => _lifecycle.cancelBooking(
        bookingId,
        isDriver: isDriver,
        reason: reason,
      ),
    );
  }

  @override
  Future<Result<void>> markGoodsHandedOver(String bookingId) {
    return _executeWithOfflineSupport(
      actionType: 'mark_goods_handed_over',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.markGoodsHandedOver(bookingId),
    );
  }

  @override
  Future<Result<void>> markPaymentSent(String bookingId) {
    return _executeWithOfflineSupport(
      actionType: 'mark_payment_sent',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.markPaymentSent(bookingId),
    );
  }

  @override
  Future<Result<void>> confirmGoodsReceivedByClient(String bookingId) {
    return _executeWithOfflineSupport(
      actionType: 'confirm_goods_received_by_client',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.confirmGoodsReceivedByClient(bookingId),
    );
  }

  @override
  Future<Result<void>> confirmGoodsReceived(
    String bookingId, {
    File? pickupPhoto,
  }) {
    // Note: Offline queue currently does not serialize File objects well,
    // so we execute online for now, or you'd need to store the local file path.
    return _executeWithOfflineSupport(
      actionType: 'confirm_goods_received',
      payload: {'bookingId': bookingId},
      onlineAction: () =>
          _lifecycle.confirmGoodsReceived(bookingId, pickupPhoto: pickupPhoto),
    );
  }

  @override
  Future<Result<void>> confirmPaymentReceived(String bookingId) {
    return _executeWithOfflineSupport(
      actionType: 'confirm_payment_received',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.confirmPaymentReceived(bookingId),
    );
  }

  @override
  Future<Result<void>> markGoodsDelivered(
    String bookingId, {
    File? deliveryPhoto,
  }) {
    return _executeWithOfflineSupport(
      actionType: 'mark_goods_delivered',
      payload: {'bookingId': bookingId},
      onlineAction: () => _lifecycle.markGoodsDelivered(
        bookingId,
        deliveryPhoto: deliveryPhoto,
      ),
    );
  }

  @override
  Future<Result<void>> markGoodsDeliveredWithCode(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  }) {
    return _executeWithOfflineSupport(
      actionType: 'mark_goods_delivered_with_code',
      payload: {'bookingId': bookingId, 'code': code},
      onlineAction: () => _lifecycle.markGoodsDeliveredWithCode(
        bookingId,
        code,
        deliveryPhoto: deliveryPhoto,
      ),
    );
  }

  @override
  Future<Result<void>> createDirectBooking({
    required String userId,
    required String driverId,
    required String tripId,
  }) {
    return _executeWithOfflineSupport(
      actionType: 'create_direct_booking',
      payload: {'userId': userId, 'driverId': driverId, 'tripId': tripId},
      onlineAction: () => _service.createDirectBooking(
        userId: userId,
        driverId: driverId,
        tripId: tripId,
      ),
    );
  }

  @override
  Future<Result<String>> createBookingWithFirstMessage({
    required String tripId,
    required String driverId,
    required String firstMessageContent,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final bookingId = await _service.createBookingWithFirstMessage(
        tripId: tripId,
        driverId: driverId,
        firstMessageContent: firstMessageContent,
        type: type,
        metadata: metadata,
      );
      return Result.success(bookingId);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<BookingStatus?>> getBookingStatus(String bookingId) async {
    try {
      final status = await _service.getBookingStatus(bookingId);
      return Result.success(status);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<String?>> getRecipientRoleForUser(
    String bookingId,
    String userId,
  ) async {
    try {
      final role = await _service.getRecipientRoleForUser(bookingId, userId);
      return Result.success(role);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }
}
