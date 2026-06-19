// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Offer {

 String get id;@JsonKey(name: 'shipment_id') String get shipmentId;@JsonKey(name: 'driver_id') String get driverId; double get price;@JsonKey(unknownEnumValue: OfferStatus.sent) OfferStatus get status;@JsonKey(name: 'rejection_reason') String? get rejectionReason; String? get message; Map<String, dynamic> get metadata;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;// Relations (from JOINs)
@JsonKey(name: 'profiles') Profile? get driver;@JsonKey(name: 'shipments') Shipment? get shipment;
/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfferCopyWith<Offer> get copyWith => _$OfferCopyWithImpl<Offer>(this as Offer, _$identity);

  /// Serializes this Offer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Offer&&(identical(other.id, id) || other.id == id)&&(identical(other.shipmentId, shipmentId) || other.shipmentId == shipmentId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.shipment, shipment) || other.shipment == shipment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shipmentId,driverId,price,status,rejectionReason,message,const DeepCollectionEquality().hash(metadata),createdAt,updatedAt,driver,shipment);

@override
String toString() {
  return 'Offer(id: $id, shipmentId: $shipmentId, driverId: $driverId, price: $price, status: $status, rejectionReason: $rejectionReason, message: $message, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt, driver: $driver, shipment: $shipment)';
}


}

/// @nodoc
abstract mixin class $OfferCopyWith<$Res>  {
  factory $OfferCopyWith(Offer value, $Res Function(Offer) _then) = _$OfferCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'shipment_id') String shipmentId,@JsonKey(name: 'driver_id') String driverId, double price,@JsonKey(unknownEnumValue: OfferStatus.sent) OfferStatus status,@JsonKey(name: 'rejection_reason') String? rejectionReason, String? message, Map<String, dynamic> metadata,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'profiles') Profile? driver,@JsonKey(name: 'shipments') Shipment? shipment
});


$ProfileCopyWith<$Res>? get driver;$ShipmentCopyWith<$Res>? get shipment;

}
/// @nodoc
class _$OfferCopyWithImpl<$Res>
    implements $OfferCopyWith<$Res> {
  _$OfferCopyWithImpl(this._self, this._then);

  final Offer _self;
  final $Res Function(Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shipmentId = null,Object? driverId = null,Object? price = null,Object? status = null,Object? rejectionReason = freezed,Object? message = freezed,Object? metadata = null,Object? createdAt = null,Object? updatedAt = freezed,Object? driver = freezed,Object? shipment = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shipmentId: null == shipmentId ? _self.shipmentId : shipmentId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OfferStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,driver: freezed == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as Profile?,shipment: freezed == shipment ? _self.shipment : shipment // ignore: cast_nullable_to_non_nullable
as Shipment?,
  ));
}
/// Create a copy of Offer
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
}/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentCopyWith<$Res>? get shipment {
    if (_self.shipment == null) {
    return null;
  }

  return $ShipmentCopyWith<$Res>(_self.shipment!, (value) {
    return _then(_self.copyWith(shipment: value));
  });
}
}


/// Adds pattern-matching-related methods to [Offer].
extension OfferPatterns on Offer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Offer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Offer value)  $default,){
final _that = this;
switch (_that) {
case _Offer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Offer value)?  $default,){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shipment_id')  String shipmentId, @JsonKey(name: 'driver_id')  String driverId,  double price, @JsonKey(unknownEnumValue: OfferStatus.sent)  OfferStatus status, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? message,  Map<String, dynamic> metadata, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'profiles')  Profile? driver, @JsonKey(name: 'shipments')  Shipment? shipment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.id,_that.shipmentId,_that.driverId,_that.price,_that.status,_that.rejectionReason,_that.message,_that.metadata,_that.createdAt,_that.updatedAt,_that.driver,_that.shipment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'shipment_id')  String shipmentId, @JsonKey(name: 'driver_id')  String driverId,  double price, @JsonKey(unknownEnumValue: OfferStatus.sent)  OfferStatus status, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? message,  Map<String, dynamic> metadata, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'profiles')  Profile? driver, @JsonKey(name: 'shipments')  Shipment? shipment)  $default,) {final _that = this;
switch (_that) {
case _Offer():
return $default(_that.id,_that.shipmentId,_that.driverId,_that.price,_that.status,_that.rejectionReason,_that.message,_that.metadata,_that.createdAt,_that.updatedAt,_that.driver,_that.shipment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'shipment_id')  String shipmentId, @JsonKey(name: 'driver_id')  String driverId,  double price, @JsonKey(unknownEnumValue: OfferStatus.sent)  OfferStatus status, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? message,  Map<String, dynamic> metadata, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'profiles')  Profile? driver, @JsonKey(name: 'shipments')  Shipment? shipment)?  $default,) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.id,_that.shipmentId,_that.driverId,_that.price,_that.status,_that.rejectionReason,_that.message,_that.metadata,_that.createdAt,_that.updatedAt,_that.driver,_that.shipment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Offer extends Offer {
  const _Offer({required this.id, @JsonKey(name: 'shipment_id') required this.shipmentId, @JsonKey(name: 'driver_id') required this.driverId, required this.price, @JsonKey(unknownEnumValue: OfferStatus.sent) required this.status, @JsonKey(name: 'rejection_reason') this.rejectionReason, this.message, final  Map<String, dynamic> metadata = const {}, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'profiles') this.driver, @JsonKey(name: 'shipments') this.shipment}): _metadata = metadata,super._();
  factory _Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

@override final  String id;
@override@JsonKey(name: 'shipment_id') final  String shipmentId;
@override@JsonKey(name: 'driver_id') final  String driverId;
@override final  double price;
@override@JsonKey(unknownEnumValue: OfferStatus.sent) final  OfferStatus status;
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;
@override final  String? message;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
// Relations (from JOINs)
@override@JsonKey(name: 'profiles') final  Profile? driver;
@override@JsonKey(name: 'shipments') final  Shipment? shipment;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfferCopyWith<_Offer> get copyWith => __$OfferCopyWithImpl<_Offer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Offer&&(identical(other.id, id) || other.id == id)&&(identical(other.shipmentId, shipmentId) || other.shipmentId == shipmentId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.price, price) || other.price == price)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.shipment, shipment) || other.shipment == shipment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shipmentId,driverId,price,status,rejectionReason,message,const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt,driver,shipment);

@override
String toString() {
  return 'Offer(id: $id, shipmentId: $shipmentId, driverId: $driverId, price: $price, status: $status, rejectionReason: $rejectionReason, message: $message, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt, driver: $driver, shipment: $shipment)';
}


}

/// @nodoc
abstract mixin class _$OfferCopyWith<$Res> implements $OfferCopyWith<$Res> {
  factory _$OfferCopyWith(_Offer value, $Res Function(_Offer) _then) = __$OfferCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'shipment_id') String shipmentId,@JsonKey(name: 'driver_id') String driverId, double price,@JsonKey(unknownEnumValue: OfferStatus.sent) OfferStatus status,@JsonKey(name: 'rejection_reason') String? rejectionReason, String? message, Map<String, dynamic> metadata,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'profiles') Profile? driver,@JsonKey(name: 'shipments') Shipment? shipment
});


@override $ProfileCopyWith<$Res>? get driver;@override $ShipmentCopyWith<$Res>? get shipment;

}
/// @nodoc
class __$OfferCopyWithImpl<$Res>
    implements _$OfferCopyWith<$Res> {
  __$OfferCopyWithImpl(this._self, this._then);

  final _Offer _self;
  final $Res Function(_Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shipmentId = null,Object? driverId = null,Object? price = null,Object? status = null,Object? rejectionReason = freezed,Object? message = freezed,Object? metadata = null,Object? createdAt = null,Object? updatedAt = freezed,Object? driver = freezed,Object? shipment = freezed,}) {
  return _then(_Offer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shipmentId: null == shipmentId ? _self.shipmentId : shipmentId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OfferStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,driver: freezed == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as Profile?,shipment: freezed == shipment ? _self.shipment : shipment // ignore: cast_nullable_to_non_nullable
as Shipment?,
  ));
}

/// Create a copy of Offer
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
}/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentCopyWith<$Res>? get shipment {
    if (_self.shipment == null) {
    return null;
  }

  return $ShipmentCopyWith<$Res>(_self.shipment!, (value) {
    return _then(_self.copyWith(shipment: value));
  });
}
}

// dart format on
