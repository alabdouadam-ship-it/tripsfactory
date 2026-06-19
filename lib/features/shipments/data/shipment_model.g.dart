// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shipment _$ShipmentFromJson(Map<String, dynamic> json) => _Shipment(
  id: json['id'] as String,
  senderId: json['sender_id'] as String,
  pickupLocationId: json['pickup_location_id'] as String,
  dropoffLocationId: json['dropoff_location_id'] as String,
  description: json['description'] as String?,
  weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
  widthCm: (json['width_cm'] as num?)?.toDouble(),
  heightCm: (json['height_cm'] as num?)?.toDouble(),
  lengthCm: (json['length_cm'] as num?)?.toDouble(),
  transportType: json['transport_type'] as String? ?? 'internal',
  pickupDate: json['pickup_date'] == null
      ? null
      : DateTime.parse(json['pickup_date'] as String),
  diffPrice: (json['price'] as num?)?.toDouble(),
  status: $enumDecode(
    _$ShipmentStatusEnumMap,
    json['status'],
    unknownValue: ShipmentStatus.pending,
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  pickupLat: (json['pickup_latitude'] as num?)?.toDouble(),
  pickupLng: (json['pickup_longitude'] as num?)?.toDouble(),
  dropoffLat: (json['dropoff_latitude'] as num?)?.toDouble(),
  dropoffLng: (json['dropoff_longitude'] as num?)?.toDouble(),
  pickupLocation: json['pickup_loc'] == null
      ? null
      : Location.fromJson(json['pickup_loc'] as Map<String, dynamic>),
  dropoffLocation: json['dropoff_loc'] == null
      ? null
      : Location.fromJson(json['dropoff_loc'] as Map<String, dynamic>),
  sender: json['profiles'] == null
      ? null
      : Profile.fromJson(json['profiles'] as Map<String, dynamic>),
  goodsHandedBySenderAt: json['goods_handed_by_sender_at'] == null
      ? null
      : DateTime.parse(json['goods_handed_by_sender_at'] as String),
  goodsReceivedByDriverAt: json['goods_received_by_driver_at'] == null
      ? null
      : DateTime.parse(json['goods_received_by_driver_at'] as String),
  paymentMarkedBySenderAt: json['payment_marked_by_sender_at'] == null
      ? null
      : DateTime.parse(json['payment_marked_by_sender_at'] as String),
  paymentConfirmedByDriverAt: json['payment_confirmed_by_driver_at'] == null
      ? null
      : DateTime.parse(json['payment_confirmed_by_driver_at'] as String),
  goodsDeliveredByDriverAt: json['goods_delivered_by_driver_at'] == null
      ? null
      : DateTime.parse(json['goods_delivered_by_driver_at'] as String),
  goodsReceivedByClientAt: json['goods_received_by_client_at'] == null
      ? null
      : DateTime.parse(json['goods_received_by_client_at'] as String),
  deliveryCode: json['delivery_code'] as String?,
);

Map<String, dynamic> _$ShipmentToJson(_Shipment instance) => <String, dynamic>{
  'id': instance.id,
  'sender_id': instance.senderId,
  'pickup_location_id': instance.pickupLocationId,
  'dropoff_location_id': instance.dropoffLocationId,
  'description': instance.description,
  'weight_kg': instance.weightKg,
  'width_cm': instance.widthCm,
  'height_cm': instance.heightCm,
  'length_cm': instance.lengthCm,
  'transport_type': instance.transportType,
  'pickup_date': instance.pickupDate?.toIso8601String(),
  'price': instance.diffPrice,
  'status': _$ShipmentStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'pickup_latitude': instance.pickupLat,
  'pickup_longitude': instance.pickupLng,
  'dropoff_latitude': instance.dropoffLat,
  'dropoff_longitude': instance.dropoffLng,
  'pickup_loc': instance.pickupLocation,
  'dropoff_loc': instance.dropoffLocation,
  'profiles': instance.sender,
  'goods_handed_by_sender_at': instance.goodsHandedBySenderAt
      ?.toIso8601String(),
  'goods_received_by_driver_at': instance.goodsReceivedByDriverAt
      ?.toIso8601String(),
  'payment_marked_by_sender_at': instance.paymentMarkedBySenderAt
      ?.toIso8601String(),
  'payment_confirmed_by_driver_at': instance.paymentConfirmedByDriverAt
      ?.toIso8601String(),
  'goods_delivered_by_driver_at': instance.goodsDeliveredByDriverAt
      ?.toIso8601String(),
  'goods_received_by_client_at': instance.goodsReceivedByClientAt
      ?.toIso8601String(),
  'delivery_code': instance.deliveryCode,
};

const _$ShipmentStatusEnumMap = {
  ShipmentStatus.pending: 'pending',
  ShipmentStatus.inCommunication: 'in_communication',
  ShipmentStatus.accepted: 'accepted',
  ShipmentStatus.pickedUp: 'picked_up',
  ShipmentStatus.inTransit: 'in_transit',
  ShipmentStatus.delivered: 'delivered',
  ShipmentStatus.completed: 'completed',
  ShipmentStatus.cancelled: 'cancelled',
  ShipmentStatus.expired: 'expired',
};
