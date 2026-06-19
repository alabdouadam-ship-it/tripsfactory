// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Booking _$BookingFromJson(Map<String, dynamic> json) => _Booking(
  id: json['id'] as String,
  driverId: json['traveler_id'] as String,
  offerPrice: (_readOfferPrice(json, 'offer_price') as num).toDouble(),
  status: $enumDecode(
    _$BookingStatusEnumMap,
    json['status'],
    unknownValue: BookingStatus.pending,
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  driverName: json['driverName'] as String?,
  driverAvatar: json['driverAvatar'] as String?,
  senderId: json['senderId'] as String?,
  tripId: json['trip_id'] as String?,
  requesterId: json['requester_id'] as String?,
  message: json['message'] as String?,
  pickedUpAt: json['picked_up_at'] == null
      ? null
      : DateTime.parse(json['picked_up_at'] as String),
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  trip: json['trips'] == null
      ? null
      : Trip.fromJson(json['trips'] as Map<String, dynamic>),
  driver: json['driver'] == null
      ? null
      : Profile.fromJson(json['driver'] as Map<String, dynamic>),
  requester: json['requester'] == null
      ? null
      : Profile.fromJson(json['requester'] as Map<String, dynamic>),
  goodsHandedBySenderAt: json['goods_handed_by_sender_at'] == null
      ? null
      : DateTime.parse(json['goods_handed_by_sender_at'] as String),
  goodsReceivedByDriverAt:
      _readGoodsReceived(json, 'goods_received_by_traveler_at') == null
      ? null
      : DateTime.parse(
          _readGoodsReceived(json, 'goods_received_by_traveler_at') as String,
        ),
  paymentMarkedBySenderAt: json['payment_marked_by_sender_at'] == null
      ? null
      : DateTime.parse(json['payment_marked_by_sender_at'] as String),
  paymentConfirmedByDriverAt:
      _readPaymentConfirmed(json, 'payment_confirmed_by_traveler_at') == null
      ? null
      : DateTime.parse(
          _readPaymentConfirmed(json, 'payment_confirmed_by_traveler_at')
              as String,
        ),
  goodsDeliveredByDriverAt:
      _readGoodsDelivered(json, 'goods_delivered_by_traveler_at') == null
      ? null
      : DateTime.parse(
          _readGoodsDelivered(json, 'goods_delivered_by_traveler_at') as String,
        ),
  goodsReceivedByClientAt: json['goods_received_by_client_at'] == null
      ? null
      : DateTime.parse(json['goods_received_by_client_at'] as String),
  deliveryCode: json['delivery_code'] as String?,
  pickupPhotoUrl: json['pickup_photo_url'] as String?,
  deliveryPhotoUrl: json['delivery_photo_url'] as String?,
  timeline:
      (json['timeline'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
);

Map<String, dynamic> _$BookingToJson(_Booking instance) => <String, dynamic>{
  'id': instance.id,
  'traveler_id': instance.driverId,
  'offer_price': instance.offerPrice,
  'status': _$BookingStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'driverName': instance.driverName,
  'driverAvatar': instance.driverAvatar,
  'senderId': instance.senderId,
  'trip_id': instance.tripId,
  'requester_id': instance.requesterId,
  'message': instance.message,
  'picked_up_at': instance.pickedUpAt?.toIso8601String(),
  'delivered_at': instance.deliveredAt?.toIso8601String(),
  'paid_at': instance.paidAt?.toIso8601String(),
  'trips': instance.trip,
  'driver': instance.driver,
  'requester': instance.requester,
  'goods_handed_by_sender_at': instance.goodsHandedBySenderAt
      ?.toIso8601String(),
  'goods_received_by_traveler_at': instance.goodsReceivedByDriverAt
      ?.toIso8601String(),
  'payment_marked_by_sender_at': instance.paymentMarkedBySenderAt
      ?.toIso8601String(),
  'payment_confirmed_by_traveler_at': instance.paymentConfirmedByDriverAt
      ?.toIso8601String(),
  'goods_delivered_by_traveler_at': instance.goodsDeliveredByDriverAt
      ?.toIso8601String(),
  'goods_received_by_client_at': instance.goodsReceivedByClientAt
      ?.toIso8601String(),
  'delivery_code': instance.deliveryCode,
  'pickup_photo_url': instance.pickupPhotoUrl,
  'delivery_photo_url': instance.deliveryPhotoUrl,
  'timeline': instance.timeline,
};

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.accepted: 'accepted',
  BookingStatus.rejected: 'rejected',
  BookingStatus.completed: 'completed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.inTransit: 'in_transit',
  BookingStatus.delivered: 'delivered',
  BookingStatus.inCommunication: 'in_communication',
};
