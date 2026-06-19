import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_model.freezed.dart';
part 'vehicle_model.g.dart';

double? _capacityFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@freezed
abstract class Vehicle with _$Vehicle {
  const Vehicle._();

  const factory Vehicle({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'vehicle_type') required String vehicleType,
    @JsonKey(name: 'model') String? vehicleModel,
    @JsonKey(name: 'vehicle_color') String? vehicleColor,
    @JsonKey(name: 'plate_number') String? plateNumber,
    @JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson)
    double? capacityKg,
    @JsonKey(name: 'vehicle_photo_url') String? photoUrl,
    @JsonKey(name: 'registration_doc_url') String? registrationDocUrl,
    @JsonKey(name: 'vehicle_photo_url_pending') String? vehiclePhotoUrlPending,
    @JsonKey(name: 'registration_doc_url_pending')
    String? registrationDocUrlPending,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}
