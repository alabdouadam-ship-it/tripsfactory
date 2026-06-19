// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Offer _$OfferFromJson(Map<String, dynamic> json) => _Offer(
  id: json['id'] as String,
  shipmentId: json['shipment_id'] as String,
  driverId: json['driver_id'] as String,
  price: (json['price'] as num).toDouble(),
  status: $enumDecode(
    _$OfferStatusEnumMap,
    json['status'],
    unknownValue: OfferStatus.sent,
  ),
  rejectionReason: json['rejection_reason'] as String?,
  message: json['message'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  driver: json['profiles'] == null
      ? null
      : Profile.fromJson(json['profiles'] as Map<String, dynamic>),
  shipment: json['shipments'] == null
      ? null
      : Shipment.fromJson(json['shipments'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OfferToJson(_Offer instance) => <String, dynamic>{
  'id': instance.id,
  'shipment_id': instance.shipmentId,
  'driver_id': instance.driverId,
  'price': instance.price,
  'status': _$OfferStatusEnumMap[instance.status]!,
  'rejection_reason': instance.rejectionReason,
  'message': instance.message,
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'profiles': instance.driver,
  'shipments': instance.shipment,
};

const _$OfferStatusEnumMap = {
  OfferStatus.sent: 'sent',
  OfferStatus.accepted: 'accepted',
  OfferStatus.rejected: 'rejected',
  OfferStatus.cancelled: 'cancelled',
  OfferStatus.completed: 'completed',
};
