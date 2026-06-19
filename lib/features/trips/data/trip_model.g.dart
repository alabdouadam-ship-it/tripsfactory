// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  driverId: json['traveler_id'] as String,
  originLocationId: json['origin_location_id'] as String,
  destLocationId: json['dest_location_id'] as String,
  departureTime: DateTime.parse(json['departure_time'] as String),
  maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble(),
  suggestedFlatPrice: (json['suggested_flat_price'] as num?)?.toDouble(),
  tripType: json['trip_type'] as String? ?? 'scheduled',
  status: TripStatus.fromString(json['status'] as String?),
  createdAt: DateTime.parse(json['created_at'] as String),
  originLocation: json['origin_loc'] == null
      ? null
      : Location.fromJson(json['origin_loc'] as Map<String, dynamic>),
  destLocation: json['dest_loc'] == null
      ? null
      : Location.fromJson(json['dest_loc'] as Map<String, dynamic>),
  driver: json['driver'] == null
      ? null
      : Profile.fromJson(json['driver'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'traveler_id': instance.driverId,
  'origin_location_id': instance.originLocationId,
  'dest_location_id': instance.destLocationId,
  'departure_time': instance.departureTime.toIso8601String(),
  'max_weight_kg': instance.maxWeightKg,
  'suggested_flat_price': instance.suggestedFlatPrice,
  'trip_type': instance.tripType,
  'status': _$TripStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'origin_loc': instance.originLocation,
  'dest_loc': instance.destLocation,
  'driver': instance.driver,
  'notes': instance.notes,
};

const _$TripStatusEnumMap = {
  TripStatus.available: 'available',
  TripStatus.inCommunication: 'in_communication',
  TripStatus.pendingConfirmation: 'pending_confirmation',
  TripStatus.booked: 'booked',
  TripStatus.inTransit: 'in_transit',
  TripStatus.full: 'full',
  TripStatus.cancelled: 'cancelled',
  TripStatus.completed: 'completed',
};
