import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/profile/data/profile_model.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

Object? _readPrice(Map json, String key) {
  final val = json['price'];
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

Object? _readGoodsReceived(Map json, String key) =>
    json['goods_received_by_traveler_at'] ??
    json['goods_received_by_driver_at'];

Object? _readPaymentConfirmed(Map json, String key) =>
    json['payment_confirmed_by_traveler_at'] ??
    json['payment_confirmed_by_driver_at'];

Object? _readGoodsDelivered(Map json, String key) =>
    json['goods_delivered_by_traveler_at'] ??
    json['goods_delivered_by_driver_at'];

@freezed
abstract class Booking with _$Booking {
  const Booking._();

  const factory Booking({
    required String id,
    @JsonKey(name: 'traveler_id') required String driverId,
    @JsonKey(name: 'price', readValue: _readPrice)
    required double price,
    @JsonKey(unknownEnumValue: BookingStatus.pending)
    required BookingStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,

    // Relations (flattened or nested depending on JOIN)
    String? driverName,
    String? driverAvatar,
    String? senderId,
    @JsonKey(name: 'trip_id') String? tripId,
    @JsonKey(name: 'requester_id') String? requesterId,
    String? message,
    @JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,
    @JsonKey(name: 'delivered_at') DateTime? deliveredAt,
    @JsonKey(name: 'paid_at') DateTime? paidAt,

    @JsonKey(name: 'trips') Trip? trip,
    @JsonKey(name: 'driver') Profile? driver,
    @JsonKey(name: 'requester') Profile? requester,

    // Lifecycle Handshake Timestamps
    @JsonKey(name: 'goods_handed_by_sender_at') DateTime? goodsHandedBySenderAt,
    @JsonKey(
      name: 'goods_received_by_traveler_at',
      readValue: _readGoodsReceived,
    )
    DateTime? goodsReceivedByDriverAt,
    @JsonKey(name: 'payment_marked_by_sender_at')
    DateTime? paymentMarkedBySenderAt,
    @JsonKey(
      name: 'payment_confirmed_by_traveler_at',
      readValue: _readPaymentConfirmed,
    )
    DateTime? paymentConfirmedByDriverAt,
    @JsonKey(
      name: 'goods_delivered_by_traveler_at',
      readValue: _readGoodsDelivered,
    )
    DateTime? goodsDeliveredByDriverAt,
    @JsonKey(name: 'goods_received_by_client_at')
    DateTime? goodsReceivedByClientAt,
    @JsonKey(name: 'delivery_code') String? deliveryCode,
    @JsonKey(name: 'pickup_photo_url') String? pickupPhotoUrl,
    @JsonKey(name: 'delivery_photo_url') String? deliveryPhotoUrl,

    @Default([]) List<Map<String, dynamic>> timeline,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  // Computed Status Helpers
  bool get isAccepted =>
      status != BookingStatus.pending &&
      status != BookingStatus.inCommunication &&
      status != BookingStatus.rejected &&
      status != BookingStatus.cancelled;

  bool get isCollected =>
      goodsReceivedByDriverAt != null ||
      status == BookingStatus.inTransit ||
      status == BookingStatus.delivered ||
      status == BookingStatus.completed;

  bool get isPaid =>
      paymentConfirmedByDriverAt != null || status == BookingStatus.completed;

  bool get isDelivered =>
      goodsReceivedByClientAt != null ||
      goodsDeliveredByDriverAt != null ||
      status == BookingStatus.completed;

  bool get isWaitingForDriverPickupConfirm =>
      goodsHandedBySenderAt != null && goodsReceivedByDriverAt == null;

  bool get isWaitingForDriverPaymentConfirm =>
      paymentMarkedBySenderAt != null && paymentConfirmedByDriverAt == null;

  bool get isWaitingForClientDeliveryConfirm =>
      goodsDeliveredByDriverAt != null && goodsReceivedByClientAt == null;
}
