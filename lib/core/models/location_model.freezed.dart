// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Location {

 String get id;@JsonKey(name: 'province_name_en') String get provinceNameEn;@JsonKey(name: 'province_name_ar') String get provinceNameAr;@JsonKey(name: 'city_name_en') String get cityNameEn;@JsonKey(name: 'city_name_ar') String get cityNameAr;@JsonKey(name: 'town_name_en') String? get townNameEn;@JsonKey(name: 'town_name_ar') String? get townNameAr; double get latitude; double get longitude;@JsonKey(name: 'country_name_en') String get countryNameEn;@JsonKey(name: 'country_name_ar') String get countryNameAr;@JsonKey(name: 'country_code') String? get countryCode;
/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationCopyWith<Location> get copyWith => _$LocationCopyWithImpl<Location>(this as Location, _$identity);

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Location&&(identical(other.id, id) || other.id == id)&&(identical(other.provinceNameEn, provinceNameEn) || other.provinceNameEn == provinceNameEn)&&(identical(other.provinceNameAr, provinceNameAr) || other.provinceNameAr == provinceNameAr)&&(identical(other.cityNameEn, cityNameEn) || other.cityNameEn == cityNameEn)&&(identical(other.cityNameAr, cityNameAr) || other.cityNameAr == cityNameAr)&&(identical(other.townNameEn, townNameEn) || other.townNameEn == townNameEn)&&(identical(other.townNameAr, townNameAr) || other.townNameAr == townNameAr)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.countryNameEn, countryNameEn) || other.countryNameEn == countryNameEn)&&(identical(other.countryNameAr, countryNameAr) || other.countryNameAr == countryNameAr)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provinceNameEn,provinceNameAr,cityNameEn,cityNameAr,townNameEn,townNameAr,latitude,longitude,countryNameEn,countryNameAr,countryCode);

@override
String toString() {
  return 'Location(id: $id, provinceNameEn: $provinceNameEn, provinceNameAr: $provinceNameAr, cityNameEn: $cityNameEn, cityNameAr: $cityNameAr, townNameEn: $townNameEn, townNameAr: $townNameAr, latitude: $latitude, longitude: $longitude, countryNameEn: $countryNameEn, countryNameAr: $countryNameAr, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class $LocationCopyWith<$Res>  {
  factory $LocationCopyWith(Location value, $Res Function(Location) _then) = _$LocationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'province_name_en') String provinceNameEn,@JsonKey(name: 'province_name_ar') String provinceNameAr,@JsonKey(name: 'city_name_en') String cityNameEn,@JsonKey(name: 'city_name_ar') String cityNameAr,@JsonKey(name: 'town_name_en') String? townNameEn,@JsonKey(name: 'town_name_ar') String? townNameAr, double latitude, double longitude,@JsonKey(name: 'country_name_en') String countryNameEn,@JsonKey(name: 'country_name_ar') String countryNameAr,@JsonKey(name: 'country_code') String? countryCode
});




}
/// @nodoc
class _$LocationCopyWithImpl<$Res>
    implements $LocationCopyWith<$Res> {
  _$LocationCopyWithImpl(this._self, this._then);

  final Location _self;
  final $Res Function(Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? provinceNameEn = null,Object? provinceNameAr = null,Object? cityNameEn = null,Object? cityNameAr = null,Object? townNameEn = freezed,Object? townNameAr = freezed,Object? latitude = null,Object? longitude = null,Object? countryNameEn = null,Object? countryNameAr = null,Object? countryCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provinceNameEn: null == provinceNameEn ? _self.provinceNameEn : provinceNameEn // ignore: cast_nullable_to_non_nullable
as String,provinceNameAr: null == provinceNameAr ? _self.provinceNameAr : provinceNameAr // ignore: cast_nullable_to_non_nullable
as String,cityNameEn: null == cityNameEn ? _self.cityNameEn : cityNameEn // ignore: cast_nullable_to_non_nullable
as String,cityNameAr: null == cityNameAr ? _self.cityNameAr : cityNameAr // ignore: cast_nullable_to_non_nullable
as String,townNameEn: freezed == townNameEn ? _self.townNameEn : townNameEn // ignore: cast_nullable_to_non_nullable
as String?,townNameAr: freezed == townNameAr ? _self.townNameAr : townNameAr // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,countryNameEn: null == countryNameEn ? _self.countryNameEn : countryNameEn // ignore: cast_nullable_to_non_nullable
as String,countryNameAr: null == countryNameAr ? _self.countryNameAr : countryNameAr // ignore: cast_nullable_to_non_nullable
as String,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Location].
extension LocationPatterns on Location {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Location value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Location() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Location value)  $default,){
final _that = this;
switch (_that) {
case _Location():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Location value)?  $default,){
final _that = this;
switch (_that) {
case _Location() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'province_name_en')  String provinceNameEn, @JsonKey(name: 'province_name_ar')  String provinceNameAr, @JsonKey(name: 'city_name_en')  String cityNameEn, @JsonKey(name: 'city_name_ar')  String cityNameAr, @JsonKey(name: 'town_name_en')  String? townNameEn, @JsonKey(name: 'town_name_ar')  String? townNameAr,  double latitude,  double longitude, @JsonKey(name: 'country_name_en')  String countryNameEn, @JsonKey(name: 'country_name_ar')  String countryNameAr, @JsonKey(name: 'country_code')  String? countryCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.provinceNameEn,_that.provinceNameAr,_that.cityNameEn,_that.cityNameAr,_that.townNameEn,_that.townNameAr,_that.latitude,_that.longitude,_that.countryNameEn,_that.countryNameAr,_that.countryCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'province_name_en')  String provinceNameEn, @JsonKey(name: 'province_name_ar')  String provinceNameAr, @JsonKey(name: 'city_name_en')  String cityNameEn, @JsonKey(name: 'city_name_ar')  String cityNameAr, @JsonKey(name: 'town_name_en')  String? townNameEn, @JsonKey(name: 'town_name_ar')  String? townNameAr,  double latitude,  double longitude, @JsonKey(name: 'country_name_en')  String countryNameEn, @JsonKey(name: 'country_name_ar')  String countryNameAr, @JsonKey(name: 'country_code')  String? countryCode)  $default,) {final _that = this;
switch (_that) {
case _Location():
return $default(_that.id,_that.provinceNameEn,_that.provinceNameAr,_that.cityNameEn,_that.cityNameAr,_that.townNameEn,_that.townNameAr,_that.latitude,_that.longitude,_that.countryNameEn,_that.countryNameAr,_that.countryCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'province_name_en')  String provinceNameEn, @JsonKey(name: 'province_name_ar')  String provinceNameAr, @JsonKey(name: 'city_name_en')  String cityNameEn, @JsonKey(name: 'city_name_ar')  String cityNameAr, @JsonKey(name: 'town_name_en')  String? townNameEn, @JsonKey(name: 'town_name_ar')  String? townNameAr,  double latitude,  double longitude, @JsonKey(name: 'country_name_en')  String countryNameEn, @JsonKey(name: 'country_name_ar')  String countryNameAr, @JsonKey(name: 'country_code')  String? countryCode)?  $default,) {final _that = this;
switch (_that) {
case _Location() when $default != null:
return $default(_that.id,_that.provinceNameEn,_that.provinceNameAr,_that.cityNameEn,_that.cityNameAr,_that.townNameEn,_that.townNameAr,_that.latitude,_that.longitude,_that.countryNameEn,_that.countryNameAr,_that.countryCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Location extends Location {
  const _Location({required this.id, @JsonKey(name: 'province_name_en') required this.provinceNameEn, @JsonKey(name: 'province_name_ar') required this.provinceNameAr, @JsonKey(name: 'city_name_en') required this.cityNameEn, @JsonKey(name: 'city_name_ar') required this.cityNameAr, @JsonKey(name: 'town_name_en') this.townNameEn, @JsonKey(name: 'town_name_ar') this.townNameAr, this.latitude = 0.0, this.longitude = 0.0, @JsonKey(name: 'country_name_en') required this.countryNameEn, @JsonKey(name: 'country_name_ar') required this.countryNameAr, @JsonKey(name: 'country_code') this.countryCode}): super._();
  factory _Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'province_name_en') final  String provinceNameEn;
@override@JsonKey(name: 'province_name_ar') final  String provinceNameAr;
@override@JsonKey(name: 'city_name_en') final  String cityNameEn;
@override@JsonKey(name: 'city_name_ar') final  String cityNameAr;
@override@JsonKey(name: 'town_name_en') final  String? townNameEn;
@override@JsonKey(name: 'town_name_ar') final  String? townNameAr;
@override@JsonKey() final  double latitude;
@override@JsonKey() final  double longitude;
@override@JsonKey(name: 'country_name_en') final  String countryNameEn;
@override@JsonKey(name: 'country_name_ar') final  String countryNameAr;
@override@JsonKey(name: 'country_code') final  String? countryCode;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationCopyWith<_Location> get copyWith => __$LocationCopyWithImpl<_Location>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Location&&(identical(other.id, id) || other.id == id)&&(identical(other.provinceNameEn, provinceNameEn) || other.provinceNameEn == provinceNameEn)&&(identical(other.provinceNameAr, provinceNameAr) || other.provinceNameAr == provinceNameAr)&&(identical(other.cityNameEn, cityNameEn) || other.cityNameEn == cityNameEn)&&(identical(other.cityNameAr, cityNameAr) || other.cityNameAr == cityNameAr)&&(identical(other.townNameEn, townNameEn) || other.townNameEn == townNameEn)&&(identical(other.townNameAr, townNameAr) || other.townNameAr == townNameAr)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.countryNameEn, countryNameEn) || other.countryNameEn == countryNameEn)&&(identical(other.countryNameAr, countryNameAr) || other.countryNameAr == countryNameAr)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provinceNameEn,provinceNameAr,cityNameEn,cityNameAr,townNameEn,townNameAr,latitude,longitude,countryNameEn,countryNameAr,countryCode);

@override
String toString() {
  return 'Location(id: $id, provinceNameEn: $provinceNameEn, provinceNameAr: $provinceNameAr, cityNameEn: $cityNameEn, cityNameAr: $cityNameAr, townNameEn: $townNameEn, townNameAr: $townNameAr, latitude: $latitude, longitude: $longitude, countryNameEn: $countryNameEn, countryNameAr: $countryNameAr, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class _$LocationCopyWith<$Res> implements $LocationCopyWith<$Res> {
  factory _$LocationCopyWith(_Location value, $Res Function(_Location) _then) = __$LocationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'province_name_en') String provinceNameEn,@JsonKey(name: 'province_name_ar') String provinceNameAr,@JsonKey(name: 'city_name_en') String cityNameEn,@JsonKey(name: 'city_name_ar') String cityNameAr,@JsonKey(name: 'town_name_en') String? townNameEn,@JsonKey(name: 'town_name_ar') String? townNameAr, double latitude, double longitude,@JsonKey(name: 'country_name_en') String countryNameEn,@JsonKey(name: 'country_name_ar') String countryNameAr,@JsonKey(name: 'country_code') String? countryCode
});




}
/// @nodoc
class __$LocationCopyWithImpl<$Res>
    implements _$LocationCopyWith<$Res> {
  __$LocationCopyWithImpl(this._self, this._then);

  final _Location _self;
  final $Res Function(_Location) _then;

/// Create a copy of Location
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? provinceNameEn = null,Object? provinceNameAr = null,Object? cityNameEn = null,Object? cityNameAr = null,Object? townNameEn = freezed,Object? townNameAr = freezed,Object? latitude = null,Object? longitude = null,Object? countryNameEn = null,Object? countryNameAr = null,Object? countryCode = freezed,}) {
  return _then(_Location(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provinceNameEn: null == provinceNameEn ? _self.provinceNameEn : provinceNameEn // ignore: cast_nullable_to_non_nullable
as String,provinceNameAr: null == provinceNameAr ? _self.provinceNameAr : provinceNameAr // ignore: cast_nullable_to_non_nullable
as String,cityNameEn: null == cityNameEn ? _self.cityNameEn : cityNameEn // ignore: cast_nullable_to_non_nullable
as String,cityNameAr: null == cityNameAr ? _self.cityNameAr : cityNameAr // ignore: cast_nullable_to_non_nullable
as String,townNameEn: freezed == townNameEn ? _self.townNameEn : townNameEn // ignore: cast_nullable_to_non_nullable
as String?,townNameAr: freezed == townNameAr ? _self.townNameAr : townNameAr // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,countryNameEn: null == countryNameEn ? _self.countryNameEn : countryNameEn // ignore: cast_nullable_to_non_nullable
as String,countryNameAr: null == countryNameAr ? _self.countryNameAr : countryNameAr // ignore: cast_nullable_to_non_nullable
as String,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
