// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment_list_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShipmentListState {

 List<Shipment> get shipments; bool get hasMore; int get offset; bool get showCachedBanner; bool get hasNewRealtimeUpdates;
/// Create a copy of ShipmentListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentListStateCopyWith<ShipmentListState> get copyWith => _$ShipmentListStateCopyWithImpl<ShipmentListState>(this as ShipmentListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentListState&&const DeepCollectionEquality().equals(other.shipments, shipments)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.showCachedBanner, showCachedBanner) || other.showCachedBanner == showCachedBanner)&&(identical(other.hasNewRealtimeUpdates, hasNewRealtimeUpdates) || other.hasNewRealtimeUpdates == hasNewRealtimeUpdates));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(shipments),hasMore,offset,showCachedBanner,hasNewRealtimeUpdates);

@override
String toString() {
  return 'ShipmentListState(shipments: $shipments, hasMore: $hasMore, offset: $offset, showCachedBanner: $showCachedBanner, hasNewRealtimeUpdates: $hasNewRealtimeUpdates)';
}


}

/// @nodoc
abstract mixin class $ShipmentListStateCopyWith<$Res>  {
  factory $ShipmentListStateCopyWith(ShipmentListState value, $Res Function(ShipmentListState) _then) = _$ShipmentListStateCopyWithImpl;
@useResult
$Res call({
 List<Shipment> shipments, bool hasMore, int offset, bool showCachedBanner, bool hasNewRealtimeUpdates
});




}
/// @nodoc
class _$ShipmentListStateCopyWithImpl<$Res>
    implements $ShipmentListStateCopyWith<$Res> {
  _$ShipmentListStateCopyWithImpl(this._self, this._then);

  final ShipmentListState _self;
  final $Res Function(ShipmentListState) _then;

/// Create a copy of ShipmentListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shipments = null,Object? hasMore = null,Object? offset = null,Object? showCachedBanner = null,Object? hasNewRealtimeUpdates = null,}) {
  return _then(_self.copyWith(
shipments: null == shipments ? _self.shipments : shipments // ignore: cast_nullable_to_non_nullable
as List<Shipment>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,showCachedBanner: null == showCachedBanner ? _self.showCachedBanner : showCachedBanner // ignore: cast_nullable_to_non_nullable
as bool,hasNewRealtimeUpdates: null == hasNewRealtimeUpdates ? _self.hasNewRealtimeUpdates : hasNewRealtimeUpdates // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ShipmentListState].
extension ShipmentListStatePatterns on ShipmentListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShipmentListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShipmentListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShipmentListState value)  $default,){
final _that = this;
switch (_that) {
case _ShipmentListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShipmentListState value)?  $default,){
final _that = this;
switch (_that) {
case _ShipmentListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Shipment> shipments,  bool hasMore,  int offset,  bool showCachedBanner,  bool hasNewRealtimeUpdates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShipmentListState() when $default != null:
return $default(_that.shipments,_that.hasMore,_that.offset,_that.showCachedBanner,_that.hasNewRealtimeUpdates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Shipment> shipments,  bool hasMore,  int offset,  bool showCachedBanner,  bool hasNewRealtimeUpdates)  $default,) {final _that = this;
switch (_that) {
case _ShipmentListState():
return $default(_that.shipments,_that.hasMore,_that.offset,_that.showCachedBanner,_that.hasNewRealtimeUpdates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Shipment> shipments,  bool hasMore,  int offset,  bool showCachedBanner,  bool hasNewRealtimeUpdates)?  $default,) {final _that = this;
switch (_that) {
case _ShipmentListState() when $default != null:
return $default(_that.shipments,_that.hasMore,_that.offset,_that.showCachedBanner,_that.hasNewRealtimeUpdates);case _:
  return null;

}
}

}

/// @nodoc


class _ShipmentListState implements ShipmentListState {
  const _ShipmentListState({final  List<Shipment> shipments = const [], this.hasMore = true, this.offset = 0, this.showCachedBanner = false, this.hasNewRealtimeUpdates = false}): _shipments = shipments;
  

 final  List<Shipment> _shipments;
@override@JsonKey() List<Shipment> get shipments {
  if (_shipments is EqualUnmodifiableListView) return _shipments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shipments);
}

@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  int offset;
@override@JsonKey() final  bool showCachedBanner;
@override@JsonKey() final  bool hasNewRealtimeUpdates;

/// Create a copy of ShipmentListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShipmentListStateCopyWith<_ShipmentListState> get copyWith => __$ShipmentListStateCopyWithImpl<_ShipmentListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShipmentListState&&const DeepCollectionEquality().equals(other._shipments, _shipments)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.showCachedBanner, showCachedBanner) || other.showCachedBanner == showCachedBanner)&&(identical(other.hasNewRealtimeUpdates, hasNewRealtimeUpdates) || other.hasNewRealtimeUpdates == hasNewRealtimeUpdates));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_shipments),hasMore,offset,showCachedBanner,hasNewRealtimeUpdates);

@override
String toString() {
  return 'ShipmentListState(shipments: $shipments, hasMore: $hasMore, offset: $offset, showCachedBanner: $showCachedBanner, hasNewRealtimeUpdates: $hasNewRealtimeUpdates)';
}


}

/// @nodoc
abstract mixin class _$ShipmentListStateCopyWith<$Res> implements $ShipmentListStateCopyWith<$Res> {
  factory _$ShipmentListStateCopyWith(_ShipmentListState value, $Res Function(_ShipmentListState) _then) = __$ShipmentListStateCopyWithImpl;
@override @useResult
$Res call({
 List<Shipment> shipments, bool hasMore, int offset, bool showCachedBanner, bool hasNewRealtimeUpdates
});




}
/// @nodoc
class __$ShipmentListStateCopyWithImpl<$Res>
    implements _$ShipmentListStateCopyWith<$Res> {
  __$ShipmentListStateCopyWithImpl(this._self, this._then);

  final _ShipmentListState _self;
  final $Res Function(_ShipmentListState) _then;

/// Create a copy of ShipmentListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shipments = null,Object? hasMore = null,Object? offset = null,Object? showCachedBanner = null,Object? hasNewRealtimeUpdates = null,}) {
  return _then(_ShipmentListState(
shipments: null == shipments ? _self._shipments : shipments // ignore: cast_nullable_to_non_nullable
as List<Shipment>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,showCachedBanner: null == showCachedBanner ? _self.showCachedBanner : showCachedBanner // ignore: cast_nullable_to_non_nullable
as bool,hasNewRealtimeUpdates: null == hasNewRealtimeUpdates ? _self.hasNewRealtimeUpdates : hasNewRealtimeUpdates // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
