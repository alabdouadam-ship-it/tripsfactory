// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_trip_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostTripState {

 TransportType get transportType; Map<String, dynamic>? get selectedOriginCountry; Map<String, dynamic>? get selectedOriginProvince; Map<String, dynamic>? get selectedOriginCity; Map<String, dynamic>? get selectedOriginTown; Map<String, dynamic>? get selectedDestCountry; Map<String, dynamic>? get selectedDestProvince; Map<String, dynamic>? get selectedDestCity; Map<String, dynamic>? get selectedDestTown; List<Map<String, dynamic>> get countries; List<Map<String, dynamic>> get originProvinces; List<Map<String, dynamic>> get originCities; List<Map<String, dynamic>> get originTowns; List<Map<String, dynamic>> get destProvinces; List<Map<String, dynamic>> get destCities; List<Map<String, dynamic>> get destTowns; DateTime? get selectedDate; TimeOfDay? get selectedTime; List<DateTime> get repeatDates; bool get isSaving; bool get isLoadingLocations;
/// Create a copy of PostTripState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostTripStateCopyWith<PostTripState> get copyWith => _$PostTripStateCopyWithImpl<PostTripState>(this as PostTripState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostTripState&&(identical(other.transportType, transportType) || other.transportType == transportType)&&const DeepCollectionEquality().equals(other.selectedOriginCountry, selectedOriginCountry)&&const DeepCollectionEquality().equals(other.selectedOriginProvince, selectedOriginProvince)&&const DeepCollectionEquality().equals(other.selectedOriginCity, selectedOriginCity)&&const DeepCollectionEquality().equals(other.selectedOriginTown, selectedOriginTown)&&const DeepCollectionEquality().equals(other.selectedDestCountry, selectedDestCountry)&&const DeepCollectionEquality().equals(other.selectedDestProvince, selectedDestProvince)&&const DeepCollectionEquality().equals(other.selectedDestCity, selectedDestCity)&&const DeepCollectionEquality().equals(other.selectedDestTown, selectedDestTown)&&const DeepCollectionEquality().equals(other.countries, countries)&&const DeepCollectionEquality().equals(other.originProvinces, originProvinces)&&const DeepCollectionEquality().equals(other.originCities, originCities)&&const DeepCollectionEquality().equals(other.originTowns, originTowns)&&const DeepCollectionEquality().equals(other.destProvinces, destProvinces)&&const DeepCollectionEquality().equals(other.destCities, destCities)&&const DeepCollectionEquality().equals(other.destTowns, destTowns)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.selectedTime, selectedTime) || other.selectedTime == selectedTime)&&const DeepCollectionEquality().equals(other.repeatDates, repeatDates)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isLoadingLocations, isLoadingLocations) || other.isLoadingLocations == isLoadingLocations));
}


@override
int get hashCode => Object.hashAll([runtimeType,transportType,const DeepCollectionEquality().hash(selectedOriginCountry),const DeepCollectionEquality().hash(selectedOriginProvince),const DeepCollectionEquality().hash(selectedOriginCity),const DeepCollectionEquality().hash(selectedOriginTown),const DeepCollectionEquality().hash(selectedDestCountry),const DeepCollectionEquality().hash(selectedDestProvince),const DeepCollectionEquality().hash(selectedDestCity),const DeepCollectionEquality().hash(selectedDestTown),const DeepCollectionEquality().hash(countries),const DeepCollectionEquality().hash(originProvinces),const DeepCollectionEquality().hash(originCities),const DeepCollectionEquality().hash(originTowns),const DeepCollectionEquality().hash(destProvinces),const DeepCollectionEquality().hash(destCities),const DeepCollectionEquality().hash(destTowns),selectedDate,selectedTime,const DeepCollectionEquality().hash(repeatDates),isSaving,isLoadingLocations]);

@override
String toString() {
  return 'PostTripState(transportType: $transportType, selectedOriginCountry: $selectedOriginCountry, selectedOriginProvince: $selectedOriginProvince, selectedOriginCity: $selectedOriginCity, selectedOriginTown: $selectedOriginTown, selectedDestCountry: $selectedDestCountry, selectedDestProvince: $selectedDestProvince, selectedDestCity: $selectedDestCity, selectedDestTown: $selectedDestTown, countries: $countries, originProvinces: $originProvinces, originCities: $originCities, originTowns: $originTowns, destProvinces: $destProvinces, destCities: $destCities, destTowns: $destTowns, selectedDate: $selectedDate, selectedTime: $selectedTime, repeatDates: $repeatDates, isSaving: $isSaving, isLoadingLocations: $isLoadingLocations)';
}


}

/// @nodoc
abstract mixin class $PostTripStateCopyWith<$Res>  {
  factory $PostTripStateCopyWith(PostTripState value, $Res Function(PostTripState) _then) = _$PostTripStateCopyWithImpl;
@useResult
$Res call({
 TransportType transportType, Map<String, dynamic>? selectedOriginCountry, Map<String, dynamic>? selectedOriginProvince, Map<String, dynamic>? selectedOriginCity, Map<String, dynamic>? selectedOriginTown, Map<String, dynamic>? selectedDestCountry, Map<String, dynamic>? selectedDestProvince, Map<String, dynamic>? selectedDestCity, Map<String, dynamic>? selectedDestTown, List<Map<String, dynamic>> countries, List<Map<String, dynamic>> originProvinces, List<Map<String, dynamic>> originCities, List<Map<String, dynamic>> originTowns, List<Map<String, dynamic>> destProvinces, List<Map<String, dynamic>> destCities, List<Map<String, dynamic>> destTowns, DateTime? selectedDate, TimeOfDay? selectedTime, List<DateTime> repeatDates, bool isSaving, bool isLoadingLocations
});




}
/// @nodoc
class _$PostTripStateCopyWithImpl<$Res>
    implements $PostTripStateCopyWith<$Res> {
  _$PostTripStateCopyWithImpl(this._self, this._then);

  final PostTripState _self;
  final $Res Function(PostTripState) _then;

/// Create a copy of PostTripState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transportType = null,Object? selectedOriginCountry = freezed,Object? selectedOriginProvince = freezed,Object? selectedOriginCity = freezed,Object? selectedOriginTown = freezed,Object? selectedDestCountry = freezed,Object? selectedDestProvince = freezed,Object? selectedDestCity = freezed,Object? selectedDestTown = freezed,Object? countries = null,Object? originProvinces = null,Object? originCities = null,Object? originTowns = null,Object? destProvinces = null,Object? destCities = null,Object? destTowns = null,Object? selectedDate = freezed,Object? selectedTime = freezed,Object? repeatDates = null,Object? isSaving = null,Object? isLoadingLocations = null,}) {
  return _then(_self.copyWith(
transportType: null == transportType ? _self.transportType : transportType // ignore: cast_nullable_to_non_nullable
as TransportType,selectedOriginCountry: freezed == selectedOriginCountry ? _self.selectedOriginCountry : selectedOriginCountry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedOriginProvince: freezed == selectedOriginProvince ? _self.selectedOriginProvince : selectedOriginProvince // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedOriginCity: freezed == selectedOriginCity ? _self.selectedOriginCity : selectedOriginCity // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedOriginTown: freezed == selectedOriginTown ? _self.selectedOriginTown : selectedOriginTown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestCountry: freezed == selectedDestCountry ? _self.selectedDestCountry : selectedDestCountry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestProvince: freezed == selectedDestProvince ? _self.selectedDestProvince : selectedDestProvince // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestCity: freezed == selectedDestCity ? _self.selectedDestCity : selectedDestCity // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestTown: freezed == selectedDestTown ? _self.selectedDestTown : selectedDestTown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,countries: null == countries ? _self.countries : countries // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,originProvinces: null == originProvinces ? _self.originProvinces : originProvinces // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,originCities: null == originCities ? _self.originCities : originCities // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,originTowns: null == originTowns ? _self.originTowns : originTowns // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,destProvinces: null == destProvinces ? _self.destProvinces : destProvinces // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,destCities: null == destCities ? _self.destCities : destCities // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,destTowns: null == destTowns ? _self.destTowns : destTowns // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,selectedDate: freezed == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedTime: freezed == selectedTime ? _self.selectedTime : selectedTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay?,repeatDates: null == repeatDates ? _self.repeatDates : repeatDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isLoadingLocations: null == isLoadingLocations ? _self.isLoadingLocations : isLoadingLocations // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PostTripState].
extension PostTripStatePatterns on PostTripState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostTripState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostTripState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostTripState value)  $default,){
final _that = this;
switch (_that) {
case _PostTripState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostTripState value)?  $default,){
final _that = this;
switch (_that) {
case _PostTripState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransportType transportType,  Map<String, dynamic>? selectedOriginCountry,  Map<String, dynamic>? selectedOriginProvince,  Map<String, dynamic>? selectedOriginCity,  Map<String, dynamic>? selectedOriginTown,  Map<String, dynamic>? selectedDestCountry,  Map<String, dynamic>? selectedDestProvince,  Map<String, dynamic>? selectedDestCity,  Map<String, dynamic>? selectedDestTown,  List<Map<String, dynamic>> countries,  List<Map<String, dynamic>> originProvinces,  List<Map<String, dynamic>> originCities,  List<Map<String, dynamic>> originTowns,  List<Map<String, dynamic>> destProvinces,  List<Map<String, dynamic>> destCities,  List<Map<String, dynamic>> destTowns,  DateTime? selectedDate,  TimeOfDay? selectedTime,  List<DateTime> repeatDates,  bool isSaving,  bool isLoadingLocations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostTripState() when $default != null:
return $default(_that.transportType,_that.selectedOriginCountry,_that.selectedOriginProvince,_that.selectedOriginCity,_that.selectedOriginTown,_that.selectedDestCountry,_that.selectedDestProvince,_that.selectedDestCity,_that.selectedDestTown,_that.countries,_that.originProvinces,_that.originCities,_that.originTowns,_that.destProvinces,_that.destCities,_that.destTowns,_that.selectedDate,_that.selectedTime,_that.repeatDates,_that.isSaving,_that.isLoadingLocations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransportType transportType,  Map<String, dynamic>? selectedOriginCountry,  Map<String, dynamic>? selectedOriginProvince,  Map<String, dynamic>? selectedOriginCity,  Map<String, dynamic>? selectedOriginTown,  Map<String, dynamic>? selectedDestCountry,  Map<String, dynamic>? selectedDestProvince,  Map<String, dynamic>? selectedDestCity,  Map<String, dynamic>? selectedDestTown,  List<Map<String, dynamic>> countries,  List<Map<String, dynamic>> originProvinces,  List<Map<String, dynamic>> originCities,  List<Map<String, dynamic>> originTowns,  List<Map<String, dynamic>> destProvinces,  List<Map<String, dynamic>> destCities,  List<Map<String, dynamic>> destTowns,  DateTime? selectedDate,  TimeOfDay? selectedTime,  List<DateTime> repeatDates,  bool isSaving,  bool isLoadingLocations)  $default,) {final _that = this;
switch (_that) {
case _PostTripState():
return $default(_that.transportType,_that.selectedOriginCountry,_that.selectedOriginProvince,_that.selectedOriginCity,_that.selectedOriginTown,_that.selectedDestCountry,_that.selectedDestProvince,_that.selectedDestCity,_that.selectedDestTown,_that.countries,_that.originProvinces,_that.originCities,_that.originTowns,_that.destProvinces,_that.destCities,_that.destTowns,_that.selectedDate,_that.selectedTime,_that.repeatDates,_that.isSaving,_that.isLoadingLocations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransportType transportType,  Map<String, dynamic>? selectedOriginCountry,  Map<String, dynamic>? selectedOriginProvince,  Map<String, dynamic>? selectedOriginCity,  Map<String, dynamic>? selectedOriginTown,  Map<String, dynamic>? selectedDestCountry,  Map<String, dynamic>? selectedDestProvince,  Map<String, dynamic>? selectedDestCity,  Map<String, dynamic>? selectedDestTown,  List<Map<String, dynamic>> countries,  List<Map<String, dynamic>> originProvinces,  List<Map<String, dynamic>> originCities,  List<Map<String, dynamic>> originTowns,  List<Map<String, dynamic>> destProvinces,  List<Map<String, dynamic>> destCities,  List<Map<String, dynamic>> destTowns,  DateTime? selectedDate,  TimeOfDay? selectedTime,  List<DateTime> repeatDates,  bool isSaving,  bool isLoadingLocations)?  $default,) {final _that = this;
switch (_that) {
case _PostTripState() when $default != null:
return $default(_that.transportType,_that.selectedOriginCountry,_that.selectedOriginProvince,_that.selectedOriginCity,_that.selectedOriginTown,_that.selectedDestCountry,_that.selectedDestProvince,_that.selectedDestCity,_that.selectedDestTown,_that.countries,_that.originProvinces,_that.originCities,_that.originTowns,_that.destProvinces,_that.destCities,_that.destTowns,_that.selectedDate,_that.selectedTime,_that.repeatDates,_that.isSaving,_that.isLoadingLocations);case _:
  return null;

}
}

}

/// @nodoc


class _PostTripState implements PostTripState {
  const _PostTripState({this.transportType = TransportType.internal, final  Map<String, dynamic>? selectedOriginCountry, final  Map<String, dynamic>? selectedOriginProvince, final  Map<String, dynamic>? selectedOriginCity, final  Map<String, dynamic>? selectedOriginTown, final  Map<String, dynamic>? selectedDestCountry, final  Map<String, dynamic>? selectedDestProvince, final  Map<String, dynamic>? selectedDestCity, final  Map<String, dynamic>? selectedDestTown, final  List<Map<String, dynamic>> countries = const [], final  List<Map<String, dynamic>> originProvinces = const [], final  List<Map<String, dynamic>> originCities = const [], final  List<Map<String, dynamic>> originTowns = const [], final  List<Map<String, dynamic>> destProvinces = const [], final  List<Map<String, dynamic>> destCities = const [], final  List<Map<String, dynamic>> destTowns = const [], this.selectedDate, this.selectedTime, final  List<DateTime> repeatDates = const [], this.isSaving = false, this.isLoadingLocations = false}): _selectedOriginCountry = selectedOriginCountry,_selectedOriginProvince = selectedOriginProvince,_selectedOriginCity = selectedOriginCity,_selectedOriginTown = selectedOriginTown,_selectedDestCountry = selectedDestCountry,_selectedDestProvince = selectedDestProvince,_selectedDestCity = selectedDestCity,_selectedDestTown = selectedDestTown,_countries = countries,_originProvinces = originProvinces,_originCities = originCities,_originTowns = originTowns,_destProvinces = destProvinces,_destCities = destCities,_destTowns = destTowns,_repeatDates = repeatDates;
  

@override@JsonKey() final  TransportType transportType;
 final  Map<String, dynamic>? _selectedOriginCountry;
@override Map<String, dynamic>? get selectedOriginCountry {
  final value = _selectedOriginCountry;
  if (value == null) return null;
  if (_selectedOriginCountry is EqualUnmodifiableMapView) return _selectedOriginCountry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedOriginProvince;
@override Map<String, dynamic>? get selectedOriginProvince {
  final value = _selectedOriginProvince;
  if (value == null) return null;
  if (_selectedOriginProvince is EqualUnmodifiableMapView) return _selectedOriginProvince;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedOriginCity;
@override Map<String, dynamic>? get selectedOriginCity {
  final value = _selectedOriginCity;
  if (value == null) return null;
  if (_selectedOriginCity is EqualUnmodifiableMapView) return _selectedOriginCity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedOriginTown;
@override Map<String, dynamic>? get selectedOriginTown {
  final value = _selectedOriginTown;
  if (value == null) return null;
  if (_selectedOriginTown is EqualUnmodifiableMapView) return _selectedOriginTown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedDestCountry;
@override Map<String, dynamic>? get selectedDestCountry {
  final value = _selectedDestCountry;
  if (value == null) return null;
  if (_selectedDestCountry is EqualUnmodifiableMapView) return _selectedDestCountry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedDestProvince;
@override Map<String, dynamic>? get selectedDestProvince {
  final value = _selectedDestProvince;
  if (value == null) return null;
  if (_selectedDestProvince is EqualUnmodifiableMapView) return _selectedDestProvince;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedDestCity;
@override Map<String, dynamic>? get selectedDestCity {
  final value = _selectedDestCity;
  if (value == null) return null;
  if (_selectedDestCity is EqualUnmodifiableMapView) return _selectedDestCity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _selectedDestTown;
@override Map<String, dynamic>? get selectedDestTown {
  final value = _selectedDestTown;
  if (value == null) return null;
  if (_selectedDestTown is EqualUnmodifiableMapView) return _selectedDestTown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<Map<String, dynamic>> _countries;
@override@JsonKey() List<Map<String, dynamic>> get countries {
  if (_countries is EqualUnmodifiableListView) return _countries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_countries);
}

 final  List<Map<String, dynamic>> _originProvinces;
@override@JsonKey() List<Map<String, dynamic>> get originProvinces {
  if (_originProvinces is EqualUnmodifiableListView) return _originProvinces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_originProvinces);
}

 final  List<Map<String, dynamic>> _originCities;
@override@JsonKey() List<Map<String, dynamic>> get originCities {
  if (_originCities is EqualUnmodifiableListView) return _originCities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_originCities);
}

 final  List<Map<String, dynamic>> _originTowns;
@override@JsonKey() List<Map<String, dynamic>> get originTowns {
  if (_originTowns is EqualUnmodifiableListView) return _originTowns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_originTowns);
}

 final  List<Map<String, dynamic>> _destProvinces;
@override@JsonKey() List<Map<String, dynamic>> get destProvinces {
  if (_destProvinces is EqualUnmodifiableListView) return _destProvinces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destProvinces);
}

 final  List<Map<String, dynamic>> _destCities;
@override@JsonKey() List<Map<String, dynamic>> get destCities {
  if (_destCities is EqualUnmodifiableListView) return _destCities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destCities);
}

 final  List<Map<String, dynamic>> _destTowns;
@override@JsonKey() List<Map<String, dynamic>> get destTowns {
  if (_destTowns is EqualUnmodifiableListView) return _destTowns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destTowns);
}

@override final  DateTime? selectedDate;
@override final  TimeOfDay? selectedTime;
 final  List<DateTime> _repeatDates;
@override@JsonKey() List<DateTime> get repeatDates {
  if (_repeatDates is EqualUnmodifiableListView) return _repeatDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_repeatDates);
}

@override@JsonKey() final  bool isSaving;
@override@JsonKey() final  bool isLoadingLocations;

/// Create a copy of PostTripState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostTripStateCopyWith<_PostTripState> get copyWith => __$PostTripStateCopyWithImpl<_PostTripState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostTripState&&(identical(other.transportType, transportType) || other.transportType == transportType)&&const DeepCollectionEquality().equals(other._selectedOriginCountry, _selectedOriginCountry)&&const DeepCollectionEquality().equals(other._selectedOriginProvince, _selectedOriginProvince)&&const DeepCollectionEquality().equals(other._selectedOriginCity, _selectedOriginCity)&&const DeepCollectionEquality().equals(other._selectedOriginTown, _selectedOriginTown)&&const DeepCollectionEquality().equals(other._selectedDestCountry, _selectedDestCountry)&&const DeepCollectionEquality().equals(other._selectedDestProvince, _selectedDestProvince)&&const DeepCollectionEquality().equals(other._selectedDestCity, _selectedDestCity)&&const DeepCollectionEquality().equals(other._selectedDestTown, _selectedDestTown)&&const DeepCollectionEquality().equals(other._countries, _countries)&&const DeepCollectionEquality().equals(other._originProvinces, _originProvinces)&&const DeepCollectionEquality().equals(other._originCities, _originCities)&&const DeepCollectionEquality().equals(other._originTowns, _originTowns)&&const DeepCollectionEquality().equals(other._destProvinces, _destProvinces)&&const DeepCollectionEquality().equals(other._destCities, _destCities)&&const DeepCollectionEquality().equals(other._destTowns, _destTowns)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.selectedTime, selectedTime) || other.selectedTime == selectedTime)&&const DeepCollectionEquality().equals(other._repeatDates, _repeatDates)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isLoadingLocations, isLoadingLocations) || other.isLoadingLocations == isLoadingLocations));
}


@override
int get hashCode => Object.hashAll([runtimeType,transportType,const DeepCollectionEquality().hash(_selectedOriginCountry),const DeepCollectionEquality().hash(_selectedOriginProvince),const DeepCollectionEquality().hash(_selectedOriginCity),const DeepCollectionEquality().hash(_selectedOriginTown),const DeepCollectionEquality().hash(_selectedDestCountry),const DeepCollectionEquality().hash(_selectedDestProvince),const DeepCollectionEquality().hash(_selectedDestCity),const DeepCollectionEquality().hash(_selectedDestTown),const DeepCollectionEquality().hash(_countries),const DeepCollectionEquality().hash(_originProvinces),const DeepCollectionEquality().hash(_originCities),const DeepCollectionEquality().hash(_originTowns),const DeepCollectionEquality().hash(_destProvinces),const DeepCollectionEquality().hash(_destCities),const DeepCollectionEquality().hash(_destTowns),selectedDate,selectedTime,const DeepCollectionEquality().hash(_repeatDates),isSaving,isLoadingLocations]);

@override
String toString() {
  return 'PostTripState(transportType: $transportType, selectedOriginCountry: $selectedOriginCountry, selectedOriginProvince: $selectedOriginProvince, selectedOriginCity: $selectedOriginCity, selectedOriginTown: $selectedOriginTown, selectedDestCountry: $selectedDestCountry, selectedDestProvince: $selectedDestProvince, selectedDestCity: $selectedDestCity, selectedDestTown: $selectedDestTown, countries: $countries, originProvinces: $originProvinces, originCities: $originCities, originTowns: $originTowns, destProvinces: $destProvinces, destCities: $destCities, destTowns: $destTowns, selectedDate: $selectedDate, selectedTime: $selectedTime, repeatDates: $repeatDates, isSaving: $isSaving, isLoadingLocations: $isLoadingLocations)';
}


}

/// @nodoc
abstract mixin class _$PostTripStateCopyWith<$Res> implements $PostTripStateCopyWith<$Res> {
  factory _$PostTripStateCopyWith(_PostTripState value, $Res Function(_PostTripState) _then) = __$PostTripStateCopyWithImpl;
@override @useResult
$Res call({
 TransportType transportType, Map<String, dynamic>? selectedOriginCountry, Map<String, dynamic>? selectedOriginProvince, Map<String, dynamic>? selectedOriginCity, Map<String, dynamic>? selectedOriginTown, Map<String, dynamic>? selectedDestCountry, Map<String, dynamic>? selectedDestProvince, Map<String, dynamic>? selectedDestCity, Map<String, dynamic>? selectedDestTown, List<Map<String, dynamic>> countries, List<Map<String, dynamic>> originProvinces, List<Map<String, dynamic>> originCities, List<Map<String, dynamic>> originTowns, List<Map<String, dynamic>> destProvinces, List<Map<String, dynamic>> destCities, List<Map<String, dynamic>> destTowns, DateTime? selectedDate, TimeOfDay? selectedTime, List<DateTime> repeatDates, bool isSaving, bool isLoadingLocations
});




}
/// @nodoc
class __$PostTripStateCopyWithImpl<$Res>
    implements _$PostTripStateCopyWith<$Res> {
  __$PostTripStateCopyWithImpl(this._self, this._then);

  final _PostTripState _self;
  final $Res Function(_PostTripState) _then;

/// Create a copy of PostTripState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transportType = null,Object? selectedOriginCountry = freezed,Object? selectedOriginProvince = freezed,Object? selectedOriginCity = freezed,Object? selectedOriginTown = freezed,Object? selectedDestCountry = freezed,Object? selectedDestProvince = freezed,Object? selectedDestCity = freezed,Object? selectedDestTown = freezed,Object? countries = null,Object? originProvinces = null,Object? originCities = null,Object? originTowns = null,Object? destProvinces = null,Object? destCities = null,Object? destTowns = null,Object? selectedDate = freezed,Object? selectedTime = freezed,Object? repeatDates = null,Object? isSaving = null,Object? isLoadingLocations = null,}) {
  return _then(_PostTripState(
transportType: null == transportType ? _self.transportType : transportType // ignore: cast_nullable_to_non_nullable
as TransportType,selectedOriginCountry: freezed == selectedOriginCountry ? _self._selectedOriginCountry : selectedOriginCountry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedOriginProvince: freezed == selectedOriginProvince ? _self._selectedOriginProvince : selectedOriginProvince // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedOriginCity: freezed == selectedOriginCity ? _self._selectedOriginCity : selectedOriginCity // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedOriginTown: freezed == selectedOriginTown ? _self._selectedOriginTown : selectedOriginTown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestCountry: freezed == selectedDestCountry ? _self._selectedDestCountry : selectedDestCountry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestProvince: freezed == selectedDestProvince ? _self._selectedDestProvince : selectedDestProvince // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestCity: freezed == selectedDestCity ? _self._selectedDestCity : selectedDestCity // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,selectedDestTown: freezed == selectedDestTown ? _self._selectedDestTown : selectedDestTown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,countries: null == countries ? _self._countries : countries // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,originProvinces: null == originProvinces ? _self._originProvinces : originProvinces // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,originCities: null == originCities ? _self._originCities : originCities // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,originTowns: null == originTowns ? _self._originTowns : originTowns // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,destProvinces: null == destProvinces ? _self._destProvinces : destProvinces // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,destCities: null == destCities ? _self._destCities : destCities // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,destTowns: null == destTowns ? _self._destTowns : destTowns // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,selectedDate: freezed == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedTime: freezed == selectedTime ? _self.selectedTime : selectedTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay?,repeatDates: null == repeatDates ? _self._repeatDates : repeatDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isLoadingLocations: null == isLoadingLocations ? _self.isLoadingLocations : isLoadingLocations // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
