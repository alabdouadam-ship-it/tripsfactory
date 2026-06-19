// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Vehicle _$VehicleFromJson(Map<String, dynamic> json) => _Vehicle(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  vehicleType: json['vehicle_type'] as String,
  vehicleModel: json['model'] as String?,
  vehicleColor: json['vehicle_color'] as String?,
  plateNumber: json['plate_number'] as String?,
  capacityKg: _capacityFromJson(json['capacity_kg']),
  photoUrl: json['vehicle_photo_url'] as String?,
  registrationDocUrl: json['registration_doc_url'] as String?,
  vehiclePhotoUrlPending: json['vehicle_photo_url_pending'] as String?,
  registrationDocUrlPending: json['registration_doc_url_pending'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$VehicleToJson(_Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'vehicle_type': instance.vehicleType,
  'model': instance.vehicleModel,
  'vehicle_color': instance.vehicleColor,
  'plate_number': instance.plateNumber,
  'capacity_kg': instance.capacityKg,
  'vehicle_photo_url': instance.photoUrl,
  'registration_doc_url': instance.registrationDocUrl,
  'vehicle_photo_url_pending': instance.vehiclePhotoUrlPending,
  'registration_doc_url_pending': instance.registrationDocUrlPending,
  'created_at': instance.createdAt.toIso8601String(),
};
