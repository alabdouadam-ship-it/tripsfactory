import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/features/profile/data/profile_model.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    @JsonKey(name: 'traveler_id') required String driverId,
    @JsonKey(name: 'origin_location_id') required String originLocationId,
    @JsonKey(name: 'dest_location_id') required String destLocationId,
    @JsonKey(name: 'departure_time') required DateTime departureTime,
    @JsonKey(name: 'max_weight_kg') double? maxWeightKg,
    @JsonKey(name: 'suggested_flat_price') double? suggestedFlatPrice,
    @JsonKey(name: 'trip_type') @Default('scheduled') String tripType,
    @JsonKey(
      fromJson: TripStatus.fromString,
      unknownEnumValue: TripStatus.available,
    )
    required TripStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    // Relations
    @JsonKey(name: 'origin_loc') Location? originLocation,
    @JsonKey(name: 'dest_loc') Location? destLocation,
    Profile? driver,
    String? notes,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
