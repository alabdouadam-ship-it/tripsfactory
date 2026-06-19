// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shipment {

 String get id;@JsonKey(name: 'sender_id') String get senderId;@JsonKey(name: 'pickup_location_id') String get pickupLocationId;@JsonKey(name: 'dropoff_location_id') String get dropoffLocationId; String? get description;@JsonKey(name: 'weight_kg') double get weightKg;@JsonKey(name: 'width_cm') double? get widthCm;@JsonKey(name: 'height_cm') double? get heightCm;@JsonKey(name: 'length_cm') double? get lengthCm;@JsonKey(name: 'transport_type') String get transportType;@JsonKey(name: 'pickup_date') DateTime? get pickupDate;@JsonKey(name: 'price') double? get diffPrice;@JsonKey(unknownEnumValue: ShipmentStatus.pending) ShipmentStatus get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'pickup_latitude') double? get pickupLat;@JsonKey(name: 'pickup_longitude') double? get pickupLng;@JsonKey(name: 'dropoff_latitude') double? get dropoffLat;@JsonKey(name: 'dropoff_longitude') double? get dropoffLng;// Relations
@JsonKey(name: 'pickup_loc') Location? get pickupLocation;@JsonKey(name: 'dropoff_loc') Location? get dropoffLocation;@JsonKey(name: 'profiles') Profile? get sender;// Tracking Lifecycle Timestamps
@JsonKey(name: 'goods_handed_by_sender_at') DateTime? get goodsHandedBySenderAt;@JsonKey(name: 'goods_received_by_driver_at') DateTime? get goodsReceivedByDriverAt;@JsonKey(name: 'payment_marked_by_sender_at') DateTime? get paymentMarkedBySenderAt;@JsonKey(name: 'payment_confirmed_by_driver_at') DateTime? get paymentConfirmedByDriverAt;@JsonKey(name: 'goods_delivered_by_driver_at') DateTime? get goodsDeliveredByDriverAt;@JsonKey(name: 'goods_received_by_client_at') DateTime? get goodsReceivedByClientAt;@JsonKey(name: 'delivery_code') String? get deliveryCode;
/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentCopyWith<Shipment> get copyWith => _$ShipmentCopyWithImpl<Shipment>(this as Shipment, _$identity);

  /// Serializes this Shipment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shipment&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.pickupLocationId, pickupLocationId) || other.pickupLocationId == pickupLocationId)&&(identical(other.dropoffLocationId, dropoffLocationId) || other.dropoffLocationId == dropoffLocationId)&&(identical(other.description, description) || other.description == description)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.transportType, transportType) || other.transportType == transportType)&&(identical(other.pickupDate, pickupDate) || other.pickupDate == pickupDate)&&(identical(other.diffPrice, diffPrice) || other.diffPrice == diffPrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.dropoffLat, dropoffLat) || other.dropoffLat == dropoffLat)&&(identical(other.dropoffLng, dropoffLng) || other.dropoffLng == dropoffLng)&&(identical(other.pickupLocation, pickupLocation) || other.pickupLocation == pickupLocation)&&(identical(other.dropoffLocation, dropoffLocation) || other.dropoffLocation == dropoffLocation)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.goodsHandedBySenderAt, goodsHandedBySenderAt) || other.goodsHandedBySenderAt == goodsHandedBySenderAt)&&(identical(other.goodsReceivedByDriverAt, goodsReceivedByDriverAt) || other.goodsReceivedByDriverAt == goodsReceivedByDriverAt)&&(identical(other.paymentMarkedBySenderAt, paymentMarkedBySenderAt) || other.paymentMarkedBySenderAt == paymentMarkedBySenderAt)&&(identical(other.paymentConfirmedByDriverAt, paymentConfirmedByDriverAt) || other.paymentConfirmedByDriverAt == paymentConfirmedByDriverAt)&&(identical(other.goodsDeliveredByDriverAt, goodsDeliveredByDriverAt) || other.goodsDeliveredByDriverAt == goodsDeliveredByDriverAt)&&(identical(other.goodsReceivedByClientAt, goodsReceivedByClientAt) || other.goodsReceivedByClientAt == goodsReceivedByClientAt)&&(identical(other.deliveryCode, deliveryCode) || other.deliveryCode == deliveryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,senderId,pickupLocationId,dropoffLocationId,description,weightKg,widthCm,heightCm,lengthCm,transportType,pickupDate,diffPrice,status,createdAt,pickupLat,pickupLng,dropoffLat,dropoffLng,pickupLocation,dropoffLocation,sender,goodsHandedBySenderAt,goodsReceivedByDriverAt,paymentMarkedBySenderAt,paymentConfirmedByDriverAt,goodsDeliveredByDriverAt,goodsReceivedByClientAt,deliveryCode]);

@override
String toString() {
  return 'Shipment(id: $id, senderId: $senderId, pickupLocationId: $pickupLocationId, dropoffLocationId: $dropoffLocationId, description: $description, weightKg: $weightKg, widthCm: $widthCm, heightCm: $heightCm, lengthCm: $lengthCm, transportType: $transportType, pickupDate: $pickupDate, diffPrice: $diffPrice, status: $status, createdAt: $createdAt, pickupLat: $pickupLat, pickupLng: $pickupLng, dropoffLat: $dropoffLat, dropoffLng: $dropoffLng, pickupLocation: $pickupLocation, dropoffLocation: $dropoffLocation, sender: $sender, goodsHandedBySenderAt: $goodsHandedBySenderAt, goodsReceivedByDriverAt: $goodsReceivedByDriverAt, paymentMarkedBySenderAt: $paymentMarkedBySenderAt, paymentConfirmedByDriverAt: $paymentConfirmedByDriverAt, goodsDeliveredByDriverAt: $goodsDeliveredByDriverAt, goodsReceivedByClientAt: $goodsReceivedByClientAt, deliveryCode: $deliveryCode)';
}


}

/// @nodoc
abstract mixin class $ShipmentCopyWith<$Res>  {
  factory $ShipmentCopyWith(Shipment value, $Res Function(Shipment) _then) = _$ShipmentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'sender_id') String senderId,@JsonKey(name: 'pickup_location_id') String pickupLocationId,@JsonKey(name: 'dropoff_location_id') String dropoffLocationId, String? description,@JsonKey(name: 'weight_kg') double weightKg,@JsonKey(name: 'width_cm') double? widthCm,@JsonKey(name: 'height_cm') double? heightCm,@JsonKey(name: 'length_cm') double? lengthCm,@JsonKey(name: 'transport_type') String transportType,@JsonKey(name: 'pickup_date') DateTime? pickupDate,@JsonKey(name: 'price') double? diffPrice,@JsonKey(unknownEnumValue: ShipmentStatus.pending) ShipmentStatus status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'pickup_latitude') double? pickupLat,@JsonKey(name: 'pickup_longitude') double? pickupLng,@JsonKey(name: 'dropoff_latitude') double? dropoffLat,@JsonKey(name: 'dropoff_longitude') double? dropoffLng,@JsonKey(name: 'pickup_loc') Location? pickupLocation,@JsonKey(name: 'dropoff_loc') Location? dropoffLocation,@JsonKey(name: 'profiles') Profile? sender,@JsonKey(name: 'goods_handed_by_sender_at') DateTime? goodsHandedBySenderAt,@JsonKey(name: 'goods_received_by_driver_at') DateTime? goodsReceivedByDriverAt,@JsonKey(name: 'payment_marked_by_sender_at') DateTime? paymentMarkedBySenderAt,@JsonKey(name: 'payment_confirmed_by_driver_at') DateTime? paymentConfirmedByDriverAt,@JsonKey(name: 'goods_delivered_by_driver_at') DateTime? goodsDeliveredByDriverAt,@JsonKey(name: 'goods_received_by_client_at') DateTime? goodsReceivedByClientAt,@JsonKey(name: 'delivery_code') String? deliveryCode
});


$LocationCopyWith<$Res>? get pickupLocation;$LocationCopyWith<$Res>? get dropoffLocation;$ProfileCopyWith<$Res>? get sender;

}
/// @nodoc
class _$ShipmentCopyWithImpl<$Res>
    implements $ShipmentCopyWith<$Res> {
  _$ShipmentCopyWithImpl(this._self, this._then);

  final Shipment _self;
  final $Res Function(Shipment) _then;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? pickupLocationId = null,Object? dropoffLocationId = null,Object? description = freezed,Object? weightKg = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? lengthCm = freezed,Object? transportType = null,Object? pickupDate = freezed,Object? diffPrice = freezed,Object? status = null,Object? createdAt = null,Object? pickupLat = freezed,Object? pickupLng = freezed,Object? dropoffLat = freezed,Object? dropoffLng = freezed,Object? pickupLocation = freezed,Object? dropoffLocation = freezed,Object? sender = freezed,Object? goodsHandedBySenderAt = freezed,Object? goodsReceivedByDriverAt = freezed,Object? paymentMarkedBySenderAt = freezed,Object? paymentConfirmedByDriverAt = freezed,Object? goodsDeliveredByDriverAt = freezed,Object? goodsReceivedByClientAt = freezed,Object? deliveryCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,pickupLocationId: null == pickupLocationId ? _self.pickupLocationId : pickupLocationId // ignore: cast_nullable_to_non_nullable
as String,dropoffLocationId: null == dropoffLocationId ? _self.dropoffLocationId : dropoffLocationId // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,transportType: null == transportType ? _self.transportType : transportType // ignore: cast_nullable_to_non_nullable
as String,pickupDate: freezed == pickupDate ? _self.pickupDate : pickupDate // ignore: cast_nullable_to_non_nullable
as DateTime?,diffPrice: freezed == diffPrice ? _self.diffPrice : diffPrice // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickupLat: freezed == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double?,pickupLng: freezed == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double?,dropoffLat: freezed == dropoffLat ? _self.dropoffLat : dropoffLat // ignore: cast_nullable_to_non_nullable
as double?,dropoffLng: freezed == dropoffLng ? _self.dropoffLng : dropoffLng // ignore: cast_nullable_to_non_nullable
as double?,pickupLocation: freezed == pickupLocation ? _self.pickupLocation : pickupLocation // ignore: cast_nullable_to_non_nullable
as Location?,dropoffLocation: freezed == dropoffLocation ? _self.dropoffLocation : dropoffLocation // ignore: cast_nullable_to_non_nullable
as Location?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as Profile?,goodsHandedBySenderAt: freezed == goodsHandedBySenderAt ? _self.goodsHandedBySenderAt : goodsHandedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByDriverAt: freezed == goodsReceivedByDriverAt ? _self.goodsReceivedByDriverAt : goodsReceivedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMarkedBySenderAt: freezed == paymentMarkedBySenderAt ? _self.paymentMarkedBySenderAt : paymentMarkedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentConfirmedByDriverAt: freezed == paymentConfirmedByDriverAt ? _self.paymentConfirmedByDriverAt : paymentConfirmedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsDeliveredByDriverAt: freezed == goodsDeliveredByDriverAt ? _self.goodsDeliveredByDriverAt : goodsDeliveredByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByClientAt: freezed == goodsReceivedByClientAt ? _self.goodsReceivedByClientAt : goodsReceivedByClientAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveryCode: freezed == deliveryCode ? _self.deliveryCode : deliveryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get pickupLocation {
    if (_self.pickupLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.pickupLocation!, (value) {
    return _then(_self.copyWith(pickupLocation: value));
  });
}/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get dropoffLocation {
    if (_self.dropoffLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.dropoffLocation!, (value) {
    return _then(_self.copyWith(dropoffLocation: value));
  });
}/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// Adds pattern-matching-related methods to [Shipment].
extension ShipmentPatterns on Shipment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shipment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shipment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shipment value)  $default,){
final _that = this;
switch (_that) {
case _Shipment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shipment value)?  $default,){
final _that = this;
switch (_that) {
case _Shipment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'sender_id')  String senderId, @JsonKey(name: 'pickup_location_id')  String pickupLocationId, @JsonKey(name: 'dropoff_location_id')  String dropoffLocationId,  String? description, @JsonKey(name: 'weight_kg')  double weightKg, @JsonKey(name: 'width_cm')  double? widthCm, @JsonKey(name: 'height_cm')  double? heightCm, @JsonKey(name: 'length_cm')  double? lengthCm, @JsonKey(name: 'transport_type')  String transportType, @JsonKey(name: 'pickup_date')  DateTime? pickupDate, @JsonKey(name: 'price')  double? diffPrice, @JsonKey(unknownEnumValue: ShipmentStatus.pending)  ShipmentStatus status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'pickup_latitude')  double? pickupLat, @JsonKey(name: 'pickup_longitude')  double? pickupLng, @JsonKey(name: 'dropoff_latitude')  double? dropoffLat, @JsonKey(name: 'dropoff_longitude')  double? dropoffLng, @JsonKey(name: 'pickup_loc')  Location? pickupLocation, @JsonKey(name: 'dropoff_loc')  Location? dropoffLocation, @JsonKey(name: 'profiles')  Profile? sender, @JsonKey(name: 'goods_handed_by_sender_at')  DateTime? goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_driver_at')  DateTime? goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at')  DateTime? paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_driver_at')  DateTime? paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_driver_at')  DateTime? goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at')  DateTime? goodsReceivedByClientAt, @JsonKey(name: 'delivery_code')  String? deliveryCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shipment() when $default != null:
return $default(_that.id,_that.senderId,_that.pickupLocationId,_that.dropoffLocationId,_that.description,_that.weightKg,_that.widthCm,_that.heightCm,_that.lengthCm,_that.transportType,_that.pickupDate,_that.diffPrice,_that.status,_that.createdAt,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.pickupLocation,_that.dropoffLocation,_that.sender,_that.goodsHandedBySenderAt,_that.goodsReceivedByDriverAt,_that.paymentMarkedBySenderAt,_that.paymentConfirmedByDriverAt,_that.goodsDeliveredByDriverAt,_that.goodsReceivedByClientAt,_that.deliveryCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'sender_id')  String senderId, @JsonKey(name: 'pickup_location_id')  String pickupLocationId, @JsonKey(name: 'dropoff_location_id')  String dropoffLocationId,  String? description, @JsonKey(name: 'weight_kg')  double weightKg, @JsonKey(name: 'width_cm')  double? widthCm, @JsonKey(name: 'height_cm')  double? heightCm, @JsonKey(name: 'length_cm')  double? lengthCm, @JsonKey(name: 'transport_type')  String transportType, @JsonKey(name: 'pickup_date')  DateTime? pickupDate, @JsonKey(name: 'price')  double? diffPrice, @JsonKey(unknownEnumValue: ShipmentStatus.pending)  ShipmentStatus status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'pickup_latitude')  double? pickupLat, @JsonKey(name: 'pickup_longitude')  double? pickupLng, @JsonKey(name: 'dropoff_latitude')  double? dropoffLat, @JsonKey(name: 'dropoff_longitude')  double? dropoffLng, @JsonKey(name: 'pickup_loc')  Location? pickupLocation, @JsonKey(name: 'dropoff_loc')  Location? dropoffLocation, @JsonKey(name: 'profiles')  Profile? sender, @JsonKey(name: 'goods_handed_by_sender_at')  DateTime? goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_driver_at')  DateTime? goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at')  DateTime? paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_driver_at')  DateTime? paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_driver_at')  DateTime? goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at')  DateTime? goodsReceivedByClientAt, @JsonKey(name: 'delivery_code')  String? deliveryCode)  $default,) {final _that = this;
switch (_that) {
case _Shipment():
return $default(_that.id,_that.senderId,_that.pickupLocationId,_that.dropoffLocationId,_that.description,_that.weightKg,_that.widthCm,_that.heightCm,_that.lengthCm,_that.transportType,_that.pickupDate,_that.diffPrice,_that.status,_that.createdAt,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.pickupLocation,_that.dropoffLocation,_that.sender,_that.goodsHandedBySenderAt,_that.goodsReceivedByDriverAt,_that.paymentMarkedBySenderAt,_that.paymentConfirmedByDriverAt,_that.goodsDeliveredByDriverAt,_that.goodsReceivedByClientAt,_that.deliveryCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'sender_id')  String senderId, @JsonKey(name: 'pickup_location_id')  String pickupLocationId, @JsonKey(name: 'dropoff_location_id')  String dropoffLocationId,  String? description, @JsonKey(name: 'weight_kg')  double weightKg, @JsonKey(name: 'width_cm')  double? widthCm, @JsonKey(name: 'height_cm')  double? heightCm, @JsonKey(name: 'length_cm')  double? lengthCm, @JsonKey(name: 'transport_type')  String transportType, @JsonKey(name: 'pickup_date')  DateTime? pickupDate, @JsonKey(name: 'price')  double? diffPrice, @JsonKey(unknownEnumValue: ShipmentStatus.pending)  ShipmentStatus status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'pickup_latitude')  double? pickupLat, @JsonKey(name: 'pickup_longitude')  double? pickupLng, @JsonKey(name: 'dropoff_latitude')  double? dropoffLat, @JsonKey(name: 'dropoff_longitude')  double? dropoffLng, @JsonKey(name: 'pickup_loc')  Location? pickupLocation, @JsonKey(name: 'dropoff_loc')  Location? dropoffLocation, @JsonKey(name: 'profiles')  Profile? sender, @JsonKey(name: 'goods_handed_by_sender_at')  DateTime? goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_driver_at')  DateTime? goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at')  DateTime? paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_driver_at')  DateTime? paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_driver_at')  DateTime? goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at')  DateTime? goodsReceivedByClientAt, @JsonKey(name: 'delivery_code')  String? deliveryCode)?  $default,) {final _that = this;
switch (_that) {
case _Shipment() when $default != null:
return $default(_that.id,_that.senderId,_that.pickupLocationId,_that.dropoffLocationId,_that.description,_that.weightKg,_that.widthCm,_that.heightCm,_that.lengthCm,_that.transportType,_that.pickupDate,_that.diffPrice,_that.status,_that.createdAt,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.pickupLocation,_that.dropoffLocation,_that.sender,_that.goodsHandedBySenderAt,_that.goodsReceivedByDriverAt,_that.paymentMarkedBySenderAt,_that.paymentConfirmedByDriverAt,_that.goodsDeliveredByDriverAt,_that.goodsReceivedByClientAt,_that.deliveryCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shipment implements Shipment {
  const _Shipment({required this.id, @JsonKey(name: 'sender_id') required this.senderId, @JsonKey(name: 'pickup_location_id') required this.pickupLocationId, @JsonKey(name: 'dropoff_location_id') required this.dropoffLocationId, this.description, @JsonKey(name: 'weight_kg') this.weightKg = 0.0, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'length_cm') this.lengthCm, @JsonKey(name: 'transport_type') this.transportType = 'internal', @JsonKey(name: 'pickup_date') this.pickupDate, @JsonKey(name: 'price') this.diffPrice, @JsonKey(unknownEnumValue: ShipmentStatus.pending) required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'pickup_latitude') this.pickupLat, @JsonKey(name: 'pickup_longitude') this.pickupLng, @JsonKey(name: 'dropoff_latitude') this.dropoffLat, @JsonKey(name: 'dropoff_longitude') this.dropoffLng, @JsonKey(name: 'pickup_loc') this.pickupLocation, @JsonKey(name: 'dropoff_loc') this.dropoffLocation, @JsonKey(name: 'profiles') this.sender, @JsonKey(name: 'goods_handed_by_sender_at') this.goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_driver_at') this.goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at') this.paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_driver_at') this.paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_driver_at') this.goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at') this.goodsReceivedByClientAt, @JsonKey(name: 'delivery_code') this.deliveryCode});
  factory _Shipment.fromJson(Map<String, dynamic> json) => _$ShipmentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'sender_id') final  String senderId;
@override@JsonKey(name: 'pickup_location_id') final  String pickupLocationId;
@override@JsonKey(name: 'dropoff_location_id') final  String dropoffLocationId;
@override final  String? description;
@override@JsonKey(name: 'weight_kg') final  double weightKg;
@override@JsonKey(name: 'width_cm') final  double? widthCm;
@override@JsonKey(name: 'height_cm') final  double? heightCm;
@override@JsonKey(name: 'length_cm') final  double? lengthCm;
@override@JsonKey(name: 'transport_type') final  String transportType;
@override@JsonKey(name: 'pickup_date') final  DateTime? pickupDate;
@override@JsonKey(name: 'price') final  double? diffPrice;
@override@JsonKey(unknownEnumValue: ShipmentStatus.pending) final  ShipmentStatus status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'pickup_latitude') final  double? pickupLat;
@override@JsonKey(name: 'pickup_longitude') final  double? pickupLng;
@override@JsonKey(name: 'dropoff_latitude') final  double? dropoffLat;
@override@JsonKey(name: 'dropoff_longitude') final  double? dropoffLng;
// Relations
@override@JsonKey(name: 'pickup_loc') final  Location? pickupLocation;
@override@JsonKey(name: 'dropoff_loc') final  Location? dropoffLocation;
@override@JsonKey(name: 'profiles') final  Profile? sender;
// Tracking Lifecycle Timestamps
@override@JsonKey(name: 'goods_handed_by_sender_at') final  DateTime? goodsHandedBySenderAt;
@override@JsonKey(name: 'goods_received_by_driver_at') final  DateTime? goodsReceivedByDriverAt;
@override@JsonKey(name: 'payment_marked_by_sender_at') final  DateTime? paymentMarkedBySenderAt;
@override@JsonKey(name: 'payment_confirmed_by_driver_at') final  DateTime? paymentConfirmedByDriverAt;
@override@JsonKey(name: 'goods_delivered_by_driver_at') final  DateTime? goodsDeliveredByDriverAt;
@override@JsonKey(name: 'goods_received_by_client_at') final  DateTime? goodsReceivedByClientAt;
@override@JsonKey(name: 'delivery_code') final  String? deliveryCode;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShipmentCopyWith<_Shipment> get copyWith => __$ShipmentCopyWithImpl<_Shipment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShipmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shipment&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.pickupLocationId, pickupLocationId) || other.pickupLocationId == pickupLocationId)&&(identical(other.dropoffLocationId, dropoffLocationId) || other.dropoffLocationId == dropoffLocationId)&&(identical(other.description, description) || other.description == description)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.transportType, transportType) || other.transportType == transportType)&&(identical(other.pickupDate, pickupDate) || other.pickupDate == pickupDate)&&(identical(other.diffPrice, diffPrice) || other.diffPrice == diffPrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.dropoffLat, dropoffLat) || other.dropoffLat == dropoffLat)&&(identical(other.dropoffLng, dropoffLng) || other.dropoffLng == dropoffLng)&&(identical(other.pickupLocation, pickupLocation) || other.pickupLocation == pickupLocation)&&(identical(other.dropoffLocation, dropoffLocation) || other.dropoffLocation == dropoffLocation)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.goodsHandedBySenderAt, goodsHandedBySenderAt) || other.goodsHandedBySenderAt == goodsHandedBySenderAt)&&(identical(other.goodsReceivedByDriverAt, goodsReceivedByDriverAt) || other.goodsReceivedByDriverAt == goodsReceivedByDriverAt)&&(identical(other.paymentMarkedBySenderAt, paymentMarkedBySenderAt) || other.paymentMarkedBySenderAt == paymentMarkedBySenderAt)&&(identical(other.paymentConfirmedByDriverAt, paymentConfirmedByDriverAt) || other.paymentConfirmedByDriverAt == paymentConfirmedByDriverAt)&&(identical(other.goodsDeliveredByDriverAt, goodsDeliveredByDriverAt) || other.goodsDeliveredByDriverAt == goodsDeliveredByDriverAt)&&(identical(other.goodsReceivedByClientAt, goodsReceivedByClientAt) || other.goodsReceivedByClientAt == goodsReceivedByClientAt)&&(identical(other.deliveryCode, deliveryCode) || other.deliveryCode == deliveryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,senderId,pickupLocationId,dropoffLocationId,description,weightKg,widthCm,heightCm,lengthCm,transportType,pickupDate,diffPrice,status,createdAt,pickupLat,pickupLng,dropoffLat,dropoffLng,pickupLocation,dropoffLocation,sender,goodsHandedBySenderAt,goodsReceivedByDriverAt,paymentMarkedBySenderAt,paymentConfirmedByDriverAt,goodsDeliveredByDriverAt,goodsReceivedByClientAt,deliveryCode]);

@override
String toString() {
  return 'Shipment(id: $id, senderId: $senderId, pickupLocationId: $pickupLocationId, dropoffLocationId: $dropoffLocationId, description: $description, weightKg: $weightKg, widthCm: $widthCm, heightCm: $heightCm, lengthCm: $lengthCm, transportType: $transportType, pickupDate: $pickupDate, diffPrice: $diffPrice, status: $status, createdAt: $createdAt, pickupLat: $pickupLat, pickupLng: $pickupLng, dropoffLat: $dropoffLat, dropoffLng: $dropoffLng, pickupLocation: $pickupLocation, dropoffLocation: $dropoffLocation, sender: $sender, goodsHandedBySenderAt: $goodsHandedBySenderAt, goodsReceivedByDriverAt: $goodsReceivedByDriverAt, paymentMarkedBySenderAt: $paymentMarkedBySenderAt, paymentConfirmedByDriverAt: $paymentConfirmedByDriverAt, goodsDeliveredByDriverAt: $goodsDeliveredByDriverAt, goodsReceivedByClientAt: $goodsReceivedByClientAt, deliveryCode: $deliveryCode)';
}


}

/// @nodoc
abstract mixin class _$ShipmentCopyWith<$Res> implements $ShipmentCopyWith<$Res> {
  factory _$ShipmentCopyWith(_Shipment value, $Res Function(_Shipment) _then) = __$ShipmentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'sender_id') String senderId,@JsonKey(name: 'pickup_location_id') String pickupLocationId,@JsonKey(name: 'dropoff_location_id') String dropoffLocationId, String? description,@JsonKey(name: 'weight_kg') double weightKg,@JsonKey(name: 'width_cm') double? widthCm,@JsonKey(name: 'height_cm') double? heightCm,@JsonKey(name: 'length_cm') double? lengthCm,@JsonKey(name: 'transport_type') String transportType,@JsonKey(name: 'pickup_date') DateTime? pickupDate,@JsonKey(name: 'price') double? diffPrice,@JsonKey(unknownEnumValue: ShipmentStatus.pending) ShipmentStatus status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'pickup_latitude') double? pickupLat,@JsonKey(name: 'pickup_longitude') double? pickupLng,@JsonKey(name: 'dropoff_latitude') double? dropoffLat,@JsonKey(name: 'dropoff_longitude') double? dropoffLng,@JsonKey(name: 'pickup_loc') Location? pickupLocation,@JsonKey(name: 'dropoff_loc') Location? dropoffLocation,@JsonKey(name: 'profiles') Profile? sender,@JsonKey(name: 'goods_handed_by_sender_at') DateTime? goodsHandedBySenderAt,@JsonKey(name: 'goods_received_by_driver_at') DateTime? goodsReceivedByDriverAt,@JsonKey(name: 'payment_marked_by_sender_at') DateTime? paymentMarkedBySenderAt,@JsonKey(name: 'payment_confirmed_by_driver_at') DateTime? paymentConfirmedByDriverAt,@JsonKey(name: 'goods_delivered_by_driver_at') DateTime? goodsDeliveredByDriverAt,@JsonKey(name: 'goods_received_by_client_at') DateTime? goodsReceivedByClientAt,@JsonKey(name: 'delivery_code') String? deliveryCode
});


@override $LocationCopyWith<$Res>? get pickupLocation;@override $LocationCopyWith<$Res>? get dropoffLocation;@override $ProfileCopyWith<$Res>? get sender;

}
/// @nodoc
class __$ShipmentCopyWithImpl<$Res>
    implements _$ShipmentCopyWith<$Res> {
  __$ShipmentCopyWithImpl(this._self, this._then);

  final _Shipment _self;
  final $Res Function(_Shipment) _then;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? pickupLocationId = null,Object? dropoffLocationId = null,Object? description = freezed,Object? weightKg = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? lengthCm = freezed,Object? transportType = null,Object? pickupDate = freezed,Object? diffPrice = freezed,Object? status = null,Object? createdAt = null,Object? pickupLat = freezed,Object? pickupLng = freezed,Object? dropoffLat = freezed,Object? dropoffLng = freezed,Object? pickupLocation = freezed,Object? dropoffLocation = freezed,Object? sender = freezed,Object? goodsHandedBySenderAt = freezed,Object? goodsReceivedByDriverAt = freezed,Object? paymentMarkedBySenderAt = freezed,Object? paymentConfirmedByDriverAt = freezed,Object? goodsDeliveredByDriverAt = freezed,Object? goodsReceivedByClientAt = freezed,Object? deliveryCode = freezed,}) {
  return _then(_Shipment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,pickupLocationId: null == pickupLocationId ? _self.pickupLocationId : pickupLocationId // ignore: cast_nullable_to_non_nullable
as String,dropoffLocationId: null == dropoffLocationId ? _self.dropoffLocationId : dropoffLocationId // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,transportType: null == transportType ? _self.transportType : transportType // ignore: cast_nullable_to_non_nullable
as String,pickupDate: freezed == pickupDate ? _self.pickupDate : pickupDate // ignore: cast_nullable_to_non_nullable
as DateTime?,diffPrice: freezed == diffPrice ? _self.diffPrice : diffPrice // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickupLat: freezed == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double?,pickupLng: freezed == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double?,dropoffLat: freezed == dropoffLat ? _self.dropoffLat : dropoffLat // ignore: cast_nullable_to_non_nullable
as double?,dropoffLng: freezed == dropoffLng ? _self.dropoffLng : dropoffLng // ignore: cast_nullable_to_non_nullable
as double?,pickupLocation: freezed == pickupLocation ? _self.pickupLocation : pickupLocation // ignore: cast_nullable_to_non_nullable
as Location?,dropoffLocation: freezed == dropoffLocation ? _self.dropoffLocation : dropoffLocation // ignore: cast_nullable_to_non_nullable
as Location?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as Profile?,goodsHandedBySenderAt: freezed == goodsHandedBySenderAt ? _self.goodsHandedBySenderAt : goodsHandedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByDriverAt: freezed == goodsReceivedByDriverAt ? _self.goodsReceivedByDriverAt : goodsReceivedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMarkedBySenderAt: freezed == paymentMarkedBySenderAt ? _self.paymentMarkedBySenderAt : paymentMarkedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentConfirmedByDriverAt: freezed == paymentConfirmedByDriverAt ? _self.paymentConfirmedByDriverAt : paymentConfirmedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsDeliveredByDriverAt: freezed == goodsDeliveredByDriverAt ? _self.goodsDeliveredByDriverAt : goodsDeliveredByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByClientAt: freezed == goodsReceivedByClientAt ? _self.goodsReceivedByClientAt : goodsReceivedByClientAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveryCode: freezed == deliveryCode ? _self.deliveryCode : deliveryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get pickupLocation {
    if (_self.pickupLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.pickupLocation!, (value) {
    return _then(_self.copyWith(pickupLocation: value));
  });
}/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocationCopyWith<$Res>? get dropoffLocation {
    if (_self.dropoffLocation == null) {
    return null;
  }

  return $LocationCopyWith<$Res>(_self.dropoffLocation!, (value) {
    return _then(_self.copyWith(dropoffLocation: value));
  });
}/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}

// dart format on
