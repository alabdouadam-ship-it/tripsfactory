// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_list_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TripListState {

 List<Trip> get trips; Map<String, BookingStatus> get bookingStatuses; int get offset; bool get hasMore; bool get showCachedBanner; bool get isInitialLoad;
/// Create a copy of TripListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripListStateCopyWith<TripListState> get copyWith => _$TripListStateCopyWithImpl<TripListState>(this as TripListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripListState&&const DeepCollectionEquality().equals(other.trips, trips)&&const DeepCollectionEquality().equals(other.bookingStatuses, bookingStatuses)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.showCachedBanner, showCachedBanner) || other.showCachedBanner == showCachedBanner)&&(identical(other.isInitialLoad, isInitialLoad) || other.isInitialLoad == isInitialLoad));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(trips),const DeepCollectionEquality().hash(bookingStatuses),offset,hasMore,showCachedBanner,isInitialLoad);

@override
String toString() {
  return 'TripListState(trips: $trips, bookingStatuses: $bookingStatuses, offset: $offset, hasMore: $hasMore, showCachedBanner: $showCachedBanner, isInitialLoad: $isInitialLoad)';
}


}

/// @nodoc
abstract mixin class $TripListStateCopyWith<$Res>  {
  factory $TripListStateCopyWith(TripListState value, $Res Function(TripListState) _then) = _$TripListStateCopyWithImpl;
@useResult
$Res call({
 List<Trip> trips, Map<String, BookingStatus> bookingStatuses, int offset, bool hasMore, bool showCachedBanner, bool isInitialLoad
});




}
/// @nodoc
class _$TripListStateCopyWithImpl<$Res>
    implements $TripListStateCopyWith<$Res> {
  _$TripListStateCopyWithImpl(this._self, this._then);

  final TripListState _self;
  final $Res Function(TripListState) _then;

/// Create a copy of TripListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trips = null,Object? bookingStatuses = null,Object? offset = null,Object? hasMore = null,Object? showCachedBanner = null,Object? isInitialLoad = null,}) {
  return _then(_self.copyWith(
trips: null == trips ? _self.trips : trips // ignore: cast_nullable_to_non_nullable
as List<Trip>,bookingStatuses: null == bookingStatuses ? _self.bookingStatuses : bookingStatuses // ignore: cast_nullable_to_non_nullable
as Map<String, BookingStatus>,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,showCachedBanner: null == showCachedBanner ? _self.showCachedBanner : showCachedBanner // ignore: cast_nullable_to_non_nullable
as bool,isInitialLoad: null == isInitialLoad ? _self.isInitialLoad : isInitialLoad // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TripListState].
extension TripListStatePatterns on TripListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripListState value)  $default,){
final _that = this;
switch (_that) {
case _TripListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripListState value)?  $default,){
final _that = this;
switch (_that) {
case _TripListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Trip> trips,  Map<String, BookingStatus> bookingStatuses,  int offset,  bool hasMore,  bool showCachedBanner,  bool isInitialLoad)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripListState() when $default != null:
return $default(_that.trips,_that.bookingStatuses,_that.offset,_that.hasMore,_that.showCachedBanner,_that.isInitialLoad);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Trip> trips,  Map<String, BookingStatus> bookingStatuses,  int offset,  bool hasMore,  bool showCachedBanner,  bool isInitialLoad)  $default,) {final _that = this;
switch (_that) {
case _TripListState():
return $default(_that.trips,_that.bookingStatuses,_that.offset,_that.hasMore,_that.showCachedBanner,_that.isInitialLoad);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Trip> trips,  Map<String, BookingStatus> bookingStatuses,  int offset,  bool hasMore,  bool showCachedBanner,  bool isInitialLoad)?  $default,) {final _that = this;
switch (_that) {
case _TripListState() when $default != null:
return $default(_that.trips,_that.bookingStatuses,_that.offset,_that.hasMore,_that.showCachedBanner,_that.isInitialLoad);case _:
  return null;

}
}

}

/// @nodoc


class _TripListState implements TripListState {
  const _TripListState({final  List<Trip> trips = const [], final  Map<String, BookingStatus> bookingStatuses = const {}, this.offset = 0, this.hasMore = true, this.showCachedBanner = false, this.isInitialLoad = false}): _trips = trips,_bookingStatuses = bookingStatuses;
  

 final  List<Trip> _trips;
@override@JsonKey() List<Trip> get trips {
  if (_trips is EqualUnmodifiableListView) return _trips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trips);
}

 final  Map<String, BookingStatus> _bookingStatuses;
@override@JsonKey() Map<String, BookingStatus> get bookingStatuses {
  if (_bookingStatuses is EqualUnmodifiableMapView) return _bookingStatuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bookingStatuses);
}

@override@JsonKey() final  int offset;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool showCachedBanner;
@override@JsonKey() final  bool isInitialLoad;

/// Create a copy of TripListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripListStateCopyWith<_TripListState> get copyWith => __$TripListStateCopyWithImpl<_TripListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripListState&&const DeepCollectionEquality().equals(other._trips, _trips)&&const DeepCollectionEquality().equals(other._bookingStatuses, _bookingStatuses)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.showCachedBanner, showCachedBanner) || other.showCachedBanner == showCachedBanner)&&(identical(other.isInitialLoad, isInitialLoad) || other.isInitialLoad == isInitialLoad));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_trips),const DeepCollectionEquality().hash(_bookingStatuses),offset,hasMore,showCachedBanner,isInitialLoad);

@override
String toString() {
  return 'TripListState(trips: $trips, bookingStatuses: $bookingStatuses, offset: $offset, hasMore: $hasMore, showCachedBanner: $showCachedBanner, isInitialLoad: $isInitialLoad)';
}


}

/// @nodoc
abstract mixin class _$TripListStateCopyWith<$Res> implements $TripListStateCopyWith<$Res> {
  factory _$TripListStateCopyWith(_TripListState value, $Res Function(_TripListState) _then) = __$TripListStateCopyWithImpl;
@override @useResult
$Res call({
 List<Trip> trips, Map<String, BookingStatus> bookingStatuses, int offset, bool hasMore, bool showCachedBanner, bool isInitialLoad
});




}
/// @nodoc
class __$TripListStateCopyWithImpl<$Res>
    implements _$TripListStateCopyWith<$Res> {
  __$TripListStateCopyWithImpl(this._self, this._then);

  final _TripListState _self;
  final $Res Function(_TripListState) _then;

/// Create a copy of TripListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trips = null,Object? bookingStatuses = null,Object? offset = null,Object? hasMore = null,Object? showCachedBanner = null,Object? isInitialLoad = null,}) {
  return _then(_TripListState(
trips: null == trips ? _self._trips : trips // ignore: cast_nullable_to_non_nullable
as List<Trip>,bookingStatuses: null == bookingStatuses ? _self._bookingStatuses : bookingStatuses // ignore: cast_nullable_to_non_nullable
as Map<String, BookingStatus>,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,showCachedBanner: null == showCachedBanner ? _self.showCachedBanner : showCachedBanner // ignore: cast_nullable_to_non_nullable
as bool,isInitialLoad: null == isInitialLoad ? _self.isInitialLoad : isInitialLoad // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
