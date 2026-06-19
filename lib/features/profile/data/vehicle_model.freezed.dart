// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vehicle {

 String get id;@JsonKey(name: 'owner_id') String get ownerId;@JsonKey(name: 'vehicle_type') String get vehicleType;@JsonKey(name: 'model') String? get vehicleModel;@JsonKey(name: 'vehicle_color') String? get vehicleColor;@JsonKey(name: 'plate_number') String? get plateNumber;@JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson) double? get capacityKg;@JsonKey(name: 'vehicle_photo_url') String? get photoUrl;@JsonKey(name: 'registration_doc_url') String? get registrationDocUrl;@JsonKey(name: 'vehicle_photo_url_pending') String? get vehiclePhotoUrlPending;@JsonKey(name: 'registration_doc_url_pending') String? get registrationDocUrlPending;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleCopyWith<Vehicle> get copyWith => _$VehicleCopyWithImpl<Vehicle>(this as Vehicle, _$identity);

  /// Serializes this Vehicle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vehicle&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleColor, vehicleColor) || other.vehicleColor == vehicleColor)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.capacityKg, capacityKg) || other.capacityKg == capacityKg)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.registrationDocUrl, registrationDocUrl) || other.registrationDocUrl == registrationDocUrl)&&(identical(other.vehiclePhotoUrlPending, vehiclePhotoUrlPending) || other.vehiclePhotoUrlPending == vehiclePhotoUrlPending)&&(identical(other.registrationDocUrlPending, registrationDocUrlPending) || other.registrationDocUrlPending == registrationDocUrlPending)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,vehicleType,vehicleModel,vehicleColor,plateNumber,capacityKg,photoUrl,registrationDocUrl,vehiclePhotoUrlPending,registrationDocUrlPending,createdAt);

@override
String toString() {
  return 'Vehicle(id: $id, ownerId: $ownerId, vehicleType: $vehicleType, vehicleModel: $vehicleModel, vehicleColor: $vehicleColor, plateNumber: $plateNumber, capacityKg: $capacityKg, photoUrl: $photoUrl, registrationDocUrl: $registrationDocUrl, vehiclePhotoUrlPending: $vehiclePhotoUrlPending, registrationDocUrlPending: $registrationDocUrlPending, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VehicleCopyWith<$Res>  {
  factory $VehicleCopyWith(Vehicle value, $Res Function(Vehicle) _then) = _$VehicleCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'vehicle_type') String vehicleType,@JsonKey(name: 'model') String? vehicleModel,@JsonKey(name: 'vehicle_color') String? vehicleColor,@JsonKey(name: 'plate_number') String? plateNumber,@JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson) double? capacityKg,@JsonKey(name: 'vehicle_photo_url') String? photoUrl,@JsonKey(name: 'registration_doc_url') String? registrationDocUrl,@JsonKey(name: 'vehicle_photo_url_pending') String? vehiclePhotoUrlPending,@JsonKey(name: 'registration_doc_url_pending') String? registrationDocUrlPending,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$VehicleCopyWithImpl<$Res>
    implements $VehicleCopyWith<$Res> {
  _$VehicleCopyWithImpl(this._self, this._then);

  final Vehicle _self;
  final $Res Function(Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? vehicleType = null,Object? vehicleModel = freezed,Object? vehicleColor = freezed,Object? plateNumber = freezed,Object? capacityKg = freezed,Object? photoUrl = freezed,Object? registrationDocUrl = freezed,Object? vehiclePhotoUrlPending = freezed,Object? registrationDocUrlPending = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,vehicleModel: freezed == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String?,vehicleColor: freezed == vehicleColor ? _self.vehicleColor : vehicleColor // ignore: cast_nullable_to_non_nullable
as String?,plateNumber: freezed == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String?,capacityKg: freezed == capacityKg ? _self.capacityKg : capacityKg // ignore: cast_nullable_to_non_nullable
as double?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,registrationDocUrl: freezed == registrationDocUrl ? _self.registrationDocUrl : registrationDocUrl // ignore: cast_nullable_to_non_nullable
as String?,vehiclePhotoUrlPending: freezed == vehiclePhotoUrlPending ? _self.vehiclePhotoUrlPending : vehiclePhotoUrlPending // ignore: cast_nullable_to_non_nullable
as String?,registrationDocUrlPending: freezed == registrationDocUrlPending ? _self.registrationDocUrlPending : registrationDocUrlPending // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Vehicle].
extension VehiclePatterns on Vehicle {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vehicle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vehicle value)  $default,){
final _that = this;
switch (_that) {
case _Vehicle():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vehicle value)?  $default,){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'vehicle_type')  String vehicleType, @JsonKey(name: 'model')  String? vehicleModel, @JsonKey(name: 'vehicle_color')  String? vehicleColor, @JsonKey(name: 'plate_number')  String? plateNumber, @JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson)  double? capacityKg, @JsonKey(name: 'vehicle_photo_url')  String? photoUrl, @JsonKey(name: 'registration_doc_url')  String? registrationDocUrl, @JsonKey(name: 'vehicle_photo_url_pending')  String? vehiclePhotoUrlPending, @JsonKey(name: 'registration_doc_url_pending')  String? registrationDocUrlPending, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.id,_that.ownerId,_that.vehicleType,_that.vehicleModel,_that.vehicleColor,_that.plateNumber,_that.capacityKg,_that.photoUrl,_that.registrationDocUrl,_that.vehiclePhotoUrlPending,_that.registrationDocUrlPending,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'vehicle_type')  String vehicleType, @JsonKey(name: 'model')  String? vehicleModel, @JsonKey(name: 'vehicle_color')  String? vehicleColor, @JsonKey(name: 'plate_number')  String? plateNumber, @JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson)  double? capacityKg, @JsonKey(name: 'vehicle_photo_url')  String? photoUrl, @JsonKey(name: 'registration_doc_url')  String? registrationDocUrl, @JsonKey(name: 'vehicle_photo_url_pending')  String? vehiclePhotoUrlPending, @JsonKey(name: 'registration_doc_url_pending')  String? registrationDocUrlPending, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Vehicle():
return $default(_that.id,_that.ownerId,_that.vehicleType,_that.vehicleModel,_that.vehicleColor,_that.plateNumber,_that.capacityKg,_that.photoUrl,_that.registrationDocUrl,_that.vehiclePhotoUrlPending,_that.registrationDocUrlPending,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'vehicle_type')  String vehicleType, @JsonKey(name: 'model')  String? vehicleModel, @JsonKey(name: 'vehicle_color')  String? vehicleColor, @JsonKey(name: 'plate_number')  String? plateNumber, @JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson)  double? capacityKg, @JsonKey(name: 'vehicle_photo_url')  String? photoUrl, @JsonKey(name: 'registration_doc_url')  String? registrationDocUrl, @JsonKey(name: 'vehicle_photo_url_pending')  String? vehiclePhotoUrlPending, @JsonKey(name: 'registration_doc_url_pending')  String? registrationDocUrlPending, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.id,_that.ownerId,_that.vehicleType,_that.vehicleModel,_that.vehicleColor,_that.plateNumber,_that.capacityKg,_that.photoUrl,_that.registrationDocUrl,_that.vehiclePhotoUrlPending,_that.registrationDocUrlPending,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vehicle extends Vehicle {
  const _Vehicle({required this.id, @JsonKey(name: 'owner_id') required this.ownerId, @JsonKey(name: 'vehicle_type') required this.vehicleType, @JsonKey(name: 'model') this.vehicleModel, @JsonKey(name: 'vehicle_color') this.vehicleColor, @JsonKey(name: 'plate_number') this.plateNumber, @JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson) this.capacityKg, @JsonKey(name: 'vehicle_photo_url') this.photoUrl, @JsonKey(name: 'registration_doc_url') this.registrationDocUrl, @JsonKey(name: 'vehicle_photo_url_pending') this.vehiclePhotoUrlPending, @JsonKey(name: 'registration_doc_url_pending') this.registrationDocUrlPending, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

@override final  String id;
@override@JsonKey(name: 'owner_id') final  String ownerId;
@override@JsonKey(name: 'vehicle_type') final  String vehicleType;
@override@JsonKey(name: 'model') final  String? vehicleModel;
@override@JsonKey(name: 'vehicle_color') final  String? vehicleColor;
@override@JsonKey(name: 'plate_number') final  String? plateNumber;
@override@JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson) final  double? capacityKg;
@override@JsonKey(name: 'vehicle_photo_url') final  String? photoUrl;
@override@JsonKey(name: 'registration_doc_url') final  String? registrationDocUrl;
@override@JsonKey(name: 'vehicle_photo_url_pending') final  String? vehiclePhotoUrlPending;
@override@JsonKey(name: 'registration_doc_url_pending') final  String? registrationDocUrlPending;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleCopyWith<_Vehicle> get copyWith => __$VehicleCopyWithImpl<_Vehicle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vehicle&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleColor, vehicleColor) || other.vehicleColor == vehicleColor)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.capacityKg, capacityKg) || other.capacityKg == capacityKg)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.registrationDocUrl, registrationDocUrl) || other.registrationDocUrl == registrationDocUrl)&&(identical(other.vehiclePhotoUrlPending, vehiclePhotoUrlPending) || other.vehiclePhotoUrlPending == vehiclePhotoUrlPending)&&(identical(other.registrationDocUrlPending, registrationDocUrlPending) || other.registrationDocUrlPending == registrationDocUrlPending)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,vehicleType,vehicleModel,vehicleColor,plateNumber,capacityKg,photoUrl,registrationDocUrl,vehiclePhotoUrlPending,registrationDocUrlPending,createdAt);

@override
String toString() {
  return 'Vehicle(id: $id, ownerId: $ownerId, vehicleType: $vehicleType, vehicleModel: $vehicleModel, vehicleColor: $vehicleColor, plateNumber: $plateNumber, capacityKg: $capacityKg, photoUrl: $photoUrl, registrationDocUrl: $registrationDocUrl, vehiclePhotoUrlPending: $vehiclePhotoUrlPending, registrationDocUrlPending: $registrationDocUrlPending, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VehicleCopyWith<$Res> implements $VehicleCopyWith<$Res> {
  factory _$VehicleCopyWith(_Vehicle value, $Res Function(_Vehicle) _then) = __$VehicleCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'vehicle_type') String vehicleType,@JsonKey(name: 'model') String? vehicleModel,@JsonKey(name: 'vehicle_color') String? vehicleColor,@JsonKey(name: 'plate_number') String? plateNumber,@JsonKey(name: 'capacity_kg', fromJson: _capacityFromJson) double? capacityKg,@JsonKey(name: 'vehicle_photo_url') String? photoUrl,@JsonKey(name: 'registration_doc_url') String? registrationDocUrl,@JsonKey(name: 'vehicle_photo_url_pending') String? vehiclePhotoUrlPending,@JsonKey(name: 'registration_doc_url_pending') String? registrationDocUrlPending,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$VehicleCopyWithImpl<$Res>
    implements _$VehicleCopyWith<$Res> {
  __$VehicleCopyWithImpl(this._self, this._then);

  final _Vehicle _self;
  final $Res Function(_Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? vehicleType = null,Object? vehicleModel = freezed,Object? vehicleColor = freezed,Object? plateNumber = freezed,Object? capacityKg = freezed,Object? photoUrl = freezed,Object? registrationDocUrl = freezed,Object? vehiclePhotoUrlPending = freezed,Object? registrationDocUrlPending = freezed,Object? createdAt = null,}) {
  return _then(_Vehicle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,vehicleModel: freezed == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String?,vehicleColor: freezed == vehicleColor ? _self.vehicleColor : vehicleColor // ignore: cast_nullable_to_non_nullable
as String?,plateNumber: freezed == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String?,capacityKg: freezed == capacityKg ? _self.capacityKg : capacityKg // ignore: cast_nullable_to_non_nullable
as double?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,registrationDocUrl: freezed == registrationDocUrl ? _self.registrationDocUrl : registrationDocUrl // ignore: cast_nullable_to_non_nullable
as String?,vehiclePhotoUrlPending: freezed == vehiclePhotoUrlPending ? _self.vehiclePhotoUrlPending : vehiclePhotoUrlPending // ignore: cast_nullable_to_non_nullable
as String?,registrationDocUrlPending: freezed == registrationDocUrlPending ? _self.registrationDocUrlPending : registrationDocUrlPending // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
