import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/core/enums/app_enums.dart';

part 'shipment_model.freezed.dart';
part 'shipment_model.g.dart';

@freezed
abstract class Shipment with _$Shipment {
  const factory Shipment({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'pickup_location_id') required String pickupLocationId,
    @JsonKey(name: 'dropoff_location_id') required String dropoffLocationId,
    String? description,
    @JsonKey(name: 'weight_kg') @Default(0.0) double weightKg,
    @JsonKey(name: 'width_cm') double? widthCm,
    @JsonKey(name: 'height_cm') double? heightCm,
    @JsonKey(name: 'length_cm') double? lengthCm,
    @JsonKey(name: 'transport_type') @Default('internal') String transportType,
    @JsonKey(name: 'pickup_date') DateTime? pickupDate,
    @JsonKey(name: 'price') double? diffPrice,
    @JsonKey(unknownEnumValue: ShipmentStatus.pending)
    required ShipmentStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'pickup_latitude') double? pickupLat,
    @JsonKey(name: 'pickup_longitude') double? pickupLng,
    @JsonKey(name: 'dropoff_latitude') double? dropoffLat,
    @JsonKey(name: 'dropoff_longitude') double? dropoffLng,
    // Relations
    @JsonKey(name: 'pickup_loc') Location? pickupLocation,
    @JsonKey(name: 'dropoff_loc') Location? dropoffLocation,
    @JsonKey(name: 'profiles') Profile? sender,
    // Tracking Lifecycle Timestamps
    @JsonKey(name: 'goods_handed_by_sender_at') DateTime? goodsHandedBySenderAt,
    @JsonKey(name: 'goods_received_by_driver_at')
    DateTime? goodsReceivedByDriverAt,
    @JsonKey(name: 'payment_marked_by_sender_at')
    DateTime? paymentMarkedBySenderAt,
    @JsonKey(name: 'payment_confirmed_by_driver_at')
    DateTime? paymentConfirmedByDriverAt,
    @JsonKey(name: 'goods_delivered_by_driver_at')
    DateTime? goodsDeliveredByDriverAt,
    @JsonKey(name: 'goods_received_by_client_at')
    DateTime? goodsReceivedByClientAt,
    @JsonKey(name: 'delivery_code') String? deliveryCode,
  }) = _Shipment;

  factory Shipment.fromJson(Map<String, dynamic> json) =>
      _$ShipmentFromJson(json);
}

extension ShipmentStatusExtension on Shipment {
  // Computed Status Helpers
  bool get isCollected => goodsReceivedByDriverAt != null;
  bool get isPaid =>
      paymentConfirmedByDriverAt != null ||
      status == ShipmentStatus.delivered ||
      status == ShipmentStatus.completed;
  bool get isAccepted =>
      status != ShipmentStatus.pending &&
      status != ShipmentStatus.inCommunication &&
      status != ShipmentStatus.cancelled;
  bool get isWaitingForDriverPickupConfirm =>
      goodsHandedBySenderAt != null && goodsReceivedByDriverAt == null;

  bool get isWaitingForDriverPaymentConfirm =>
      paymentMarkedBySenderAt != null && paymentConfirmedByDriverAt == null;

  bool get isWaitingForClientDeliveryConfirm =>
      goodsDeliveredByDriverAt != null && goodsReceivedByClientAt == null;

  bool get canClientConfirmDelivery =>
      isCollected && goodsReceivedByClientAt == null;

  bool get isHandedOver =>
      goodsReceivedByDriverAt != null ||
      status == ShipmentStatus.pickedUp ||
      status == ShipmentStatus.inTransit ||
      status == ShipmentStatus.delivered ||
      status == ShipmentStatus.completed;

  bool get isDelivered =>
      goodsReceivedByClientAt != null ||
      goodsDeliveredByDriverAt != null ||
      status == ShipmentStatus.delivered ||
      status == ShipmentStatus.completed;
}
