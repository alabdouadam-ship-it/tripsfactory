// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Trip {

 String get id;@JsonKey(name: 'traveler_id') String get driverId;@JsonKey(name: 'origin_location_id') String get originLocationId;@JsonKey(name: 'dest_location_id') String get destLocationId;@JsonKey(name: 'departure_time') DateTime get departureTime;@JsonKey(name: 'max_weight_kg') double? get maxWeightKg;@JsonKey(name: 'suggested_flat_price') double? get suggestedFlatPrice;@JsonKey(name: 'trip_type') String get tripType;@JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available) TripStatus get status;@JsonKey(name: 'created_at') DateTime get createdAt;// Relations
@JsonKey(name: 'origin_loc') Location? get originLocation;@JsonKey(name: 'dest_loc') Location? get destLocation; Profile? get driver; String? get notes;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.originLocationId, originLocationId) || other.originLocationId == originLocationId)&&(identical(other.destLocationId, destLocationId) || other.destLocationId == destLocationId)&&(identical(other.departureTime, departureTime) || other.departureTime == departureTime)&&(identical(other.maxWeightKg, maxWeightKg) || other.maxWeightKg == maxWeightKg)&&(identical(other.suggestedFlatPrice, suggestedFlatPrice) || other.suggestedFlatPrice == suggestedFlatPrice)&&(identical(other.tripType, tripType) || other.tripType == tripType)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.originLocation, originLocation) || other.originLocation == originLocation)&&(identical(other.destLocation, destLocation) || other.destLocation == destLocation)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,driverId,originLocationId,destLocationId,departureTime,maxWeightKg,suggestedFlatPrice,tripType,status,createdAt,originLocation,destLocation,driver,notes);

@override
String toString() {
  return 'Trip(id: $id, driverId: $driverId, originLocationId: $originLocationId, destLocationId: $destLocationId, departureTime: $departureTime, maxWeightKg: $maxWeightKg, suggestedFlatPrice: $suggestedFlatPrice, tripType: $tripType, status: $status, createdAt: $createdAt, originLocation: $originLocation, destLocation: $destLocation, driver: $driver, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'traveler_id') String driverId,@JsonKey(name: 'origin_location_id') String originLocationId,@JsonKey(name: 'dest_location_id') String destLocationId,@JsonKey(name: 'departure_time') DateTime departureTime,@JsonKey(name: 'max_weight_kg') double? maxWeightKg,@JsonKey(name: 'suggested_flat_price') double? suggestedFlatPrice,@JsonKey(name: 'trip_type') String tripType,@JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available) TripStatus status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'origin_loc') Location? originLocation,@JsonKey(name: 'dest_loc') Location? destLocation, Profile? driver, String? notes
});


$LocationCopyWith<$Res>? get originLocation;$LocationCopyWith<$Res>? get destLocation;$ProfileCopyWith<$Res>? get driver;

}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? driverId = null,Object? originLocationId = null,Object? destLocationId = null,Object? departureTime = null,Object? maxWeightKg = freezed,Object? suggestedFlatPrice = freezed,Object? tripType = null,Object? status = null,Object? createdAt = null,Object? originLocation = freezed,Object? destLocation = freezed,Object? driver = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,originLocationId: null == originLocationId ? _self.originLocationId : originLocationId // ignore: cast_nullable_to_non_nullable
as String,destLocationId: null == destLocationId ? _self.destLocationId : destLocationId // ignore: cast_nullable_to_non_nullable
as String,departureTime: null == departureTime ? _self.departureTime : departureTime // ignore: cast_nullable_to_non_nullable
as DateTime,maxWeightKg: freezed == maxWeightKg ? _self.maxWeightKg : maxWeightKg // ignore: cast_nullable_to_non_nullable
as double?,suggestedFlatPrice: freezed == suggestedFlatPrice ? _self.suggestedFlatPrice : suggestedFlatPrice // ignore: cast_nullable_to_non_nullable
as double?,tripType: null == tripType ? _self.tripType : tripType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,originLocation: freezed == originLocation ? _self.originLocation : originLocation // ignore: cast_nullable_to_non_nullable
as Location?,destLocation: freezed == destLocation ? _self.destLocation : destLocation // ignore: cast_nullable_to_non_nullable
as Location?,driver: freezed == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as Profile?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get originLocation {
    if (_self.originLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.originLocation!, (value) {
    return _then(_self.copyWith(originLocation: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get destLocation {
    if (_self.destLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.destLocation!, (value) {
    return _then(_self.copyWith(destLocation: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get driver {
    if (_self.driver == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.driver!, (value) {
    return _then(_self.copyWith(driver: value));
  });
}
}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'traveler_id')  String driverId, @JsonKey(name: 'origin_location_id')  String originLocationId, @JsonKey(name: 'dest_location_id')  String destLocationId, @JsonKey(name: 'departure_time')  DateTime departureTime, @JsonKey(name: 'max_weight_kg')  double? maxWeightKg, @JsonKey(name: 'suggested_flat_price')  double? suggestedFlatPrice, @JsonKey(name: 'trip_type')  String tripType, @JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available)  TripStatus status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'origin_loc')  Location? originLocation, @JsonKey(name: 'dest_loc')  Location? destLocation,  Profile? driver,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.driverId,_that.originLocationId,_that.destLocationId,_that.departureTime,_that.maxWeightKg,_that.suggestedFlatPrice,_that.tripType,_that.status,_that.createdAt,_that.originLocation,_that.destLocation,_that.driver,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'traveler_id')  String driverId, @JsonKey(name: 'origin_location_id')  String originLocationId, @JsonKey(name: 'dest_location_id')  String destLocationId, @JsonKey(name: 'departure_time')  DateTime departureTime, @JsonKey(name: 'max_weight_kg')  double? maxWeightKg, @JsonKey(name: 'suggested_flat_price')  double? suggestedFlatPrice, @JsonKey(name: 'trip_type')  String tripType, @JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available)  TripStatus status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'origin_loc')  Location? originLocation, @JsonKey(name: 'dest_loc')  Location? destLocation,  Profile? driver,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.driverId,_that.originLocationId,_that.destLocationId,_that.departureTime,_that.maxWeightKg,_that.suggestedFlatPrice,_that.tripType,_that.status,_that.createdAt,_that.originLocation,_that.destLocation,_that.driver,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'traveler_id')  String driverId, @JsonKey(name: 'origin_location_id')  String originLocationId, @JsonKey(name: 'dest_location_id')  String destLocationId, @JsonKey(name: 'departure_time')  DateTime departureTime, @JsonKey(name: 'max_weight_kg')  double? maxWeightKg, @JsonKey(name: 'suggested_flat_price')  double? suggestedFlatPrice, @JsonKey(name: 'trip_type')  String tripType, @JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available)  TripStatus status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'origin_loc')  Location? originLocation, @JsonKey(name: 'dest_loc')  Location? destLocation,  Profile? driver,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.driverId,_that.originLocationId,_that.destLocationId,_that.departureTime,_that.maxWeightKg,_that.suggestedFlatPrice,_that.tripType,_that.status,_that.createdAt,_that.originLocation,_that.destLocation,_that.driver,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip implements Trip {
  const _Trip({required this.id, @JsonKey(name: 'traveler_id') required this.driverId, @JsonKey(name: 'origin_location_id') required this.originLocationId, @JsonKey(name: 'dest_location_id') required this.destLocationId, @JsonKey(name: 'departure_time') required this.departureTime, @JsonKey(name: 'max_weight_kg') this.maxWeightKg, @JsonKey(name: 'suggested_flat_price') this.suggestedFlatPrice, @JsonKey(name: 'trip_type') this.tripType = 'scheduled', @JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available) required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'origin_loc') this.originLocation, @JsonKey(name: 'dest_loc') this.destLocation, this.driver, this.notes});
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
@override@JsonKey(name: 'traveler_id') final  String driverId;
@override@JsonKey(name: 'origin_location_id') final  String originLocationId;
@override@JsonKey(name: 'dest_location_id') final  String destLocationId;
@override@JsonKey(name: 'departure_time') final  DateTime departureTime;
@override@JsonKey(name: 'max_weight_kg') final  double? maxWeightKg;
@override@JsonKey(name: 'suggested_flat_price') final  double? suggestedFlatPrice;
@override@JsonKey(name: 'trip_type') final  String tripType;
@override@JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available) final  TripStatus status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
// Relations
@override@JsonKey(name: 'origin_loc') final  Location? originLocation;
@override@JsonKey(name: 'dest_loc') final  Location? destLocation;
@override final  Profile? driver;
@override final  String? notes;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.originLocationId, originLocationId) || other.originLocationId == originLocationId)&&(identical(other.destLocationId, destLocationId) || other.destLocationId == destLocationId)&&(identical(other.departureTime, departureTime) || other.departureTime == departureTime)&&(identical(other.maxWeightKg, maxWeightKg) || other.maxWeightKg == maxWeightKg)&&(identical(other.suggestedFlatPrice, suggestedFlatPrice) || other.suggestedFlatPrice == suggestedFlatPrice)&&(identical(other.tripType, tripType) || other.tripType == tripType)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.originLocation, originLocation) || other.originLocation == originLocation)&&(identical(other.destLocation, destLocation) || other.destLocation == destLocation)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,driverId,originLocationId,destLocationId,departureTime,maxWeightKg,suggestedFlatPrice,tripType,status,createdAt,originLocation,destLocation,driver,notes);

@override
String toString() {
  return 'Trip(id: $id, driverId: $driverId, originLocationId: $originLocationId, destLocationId: $destLocationId, departureTime: $departureTime, maxWeightKg: $maxWeightKg, suggestedFlatPrice: $suggestedFlatPrice, tripType: $tripType, status: $status, createdAt: $createdAt, originLocation: $originLocation, destLocation: $destLocation, driver: $driver, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'traveler_id') String driverId,@JsonKey(name: 'origin_location_id') String originLocationId,@JsonKey(name: 'dest_location_id') String destLocationId,@JsonKey(name: 'departure_time') DateTime departureTime,@JsonKey(name: 'max_weight_kg') double? maxWeightKg,@JsonKey(name: 'suggested_flat_price') double? suggestedFlatPrice,@JsonKey(name: 'trip_type') String tripType,@JsonKey(fromJson: TripStatus.fromString, unknownEnumValue: TripStatus.available) TripStatus status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'origin_loc') Location? originLocation,@JsonKey(name: 'dest_loc') Location? destLocation, Profile? driver, String? notes
});


@override $LocationCopyWith<$Res>? get originLocation;@override $LocationCopyWith<$Res>? get destLocation;@override $ProfileCopyWith<$Res>? get driver;

}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? driverId = null,Object? originLocationId = null,Object? destLocationId = null,Object? departureTime = null,Object? maxWeightKg = freezed,Object? suggestedFlatPrice = freezed,Object? tripType = null,Object? status = null,Object? createdAt = null,Object? originLocation = freezed,Object? destLocation = freezed,Object? driver = freezed,Object? notes = freezed,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,originLocationId: null == originLocationId ? _self.originLocationId : originLocationId // ignore: cast_nullable_to_non_nullable
as String,destLocationId: null == destLocationId ? _self.destLocationId : destLocationId // ignore: cast_nullable_to_non_nullable
as String,departureTime: null == departureTime ? _self.departureTime : departureTime // ignore: cast_nullable_to_non_nullable
as DateTime,maxWeightKg: freezed == maxWeightKg ? _self.maxWeightKg : maxWeightKg // ignore: cast_nullable_to_non_nullable
as double?,suggestedFlatPrice: freezed == suggestedFlatPrice ? _self.suggestedFlatPrice : suggestedFlatPrice // ignore: cast_nullable_to_non_nullable
as double?,tripType: null == tripType ? _self.tripType : tripType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,originLocation: freezed == originLocation ? _self.originLocation : originLocation // ignore: cast_nullable_to_non_nullable
as Location?,destLocation: freezed == destLocation ? _self.destLocation : destLocation // ignore: cast_nullable_to_non_nullable
as Location?,driver: freezed == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as Profile?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get originLocation {
    if (_self.originLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.originLocation!, (value) {
    return _then(_self.copyWith(originLocation: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get destLocation {
    if (_self.destLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.destLocation!, (value) {
    return _then(_self.copyWith(destLocation: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get driver {
    if (_self.driver == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.driver!, (value) {
    return _then(_self.copyWith(driver: value));
  });
}
}

// dart format on
