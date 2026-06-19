// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Booking {

 String get id;@JsonKey(name: 'traveler_id') String get driverId;@JsonKey(name: 'offer_price', readValue: _readOfferPrice) double get offerPrice;@JsonKey(unknownEnumValue: BookingStatus.pending) BookingStatus get status;@JsonKey(name: 'created_at') DateTime get createdAt;// Relations (flattened or nested depending on JOIN)
 String? get driverName; String? get driverAvatar; String? get senderId;@JsonKey(name: 'trip_id') String? get tripId;@JsonKey(name: 'requester_id') String? get requesterId; String? get message;@JsonKey(name: 'picked_up_at') DateTime? get pickedUpAt;@JsonKey(name: 'delivered_at') DateTime? get deliveredAt;@JsonKey(name: 'paid_at') DateTime? get paidAt;@JsonKey(name: 'trips') Trip? get trip;@JsonKey(name: 'driver') Profile? get driver;@JsonKey(name: 'requester') Profile? get requester;// Lifecycle Handshake Timestamps
@JsonKey(name: 'goods_handed_by_sender_at') DateTime? get goodsHandedBySenderAt;@JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived) DateTime? get goodsReceivedByDriverAt;@JsonKey(name: 'payment_marked_by_sender_at') DateTime? get paymentMarkedBySenderAt;@JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed) DateTime? get paymentConfirmedByDriverAt;@JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered) DateTime? get goodsDeliveredByDriverAt;@JsonKey(name: 'goods_received_by_client_at') DateTime? get goodsReceivedByClientAt;@JsonKey(name: 'delivery_code') String? get deliveryCode;@JsonKey(name: 'pickup_photo_url') String? get pickupPhotoUrl;@JsonKey(name: 'delivery_photo_url') String? get deliveryPhotoUrl; List<Map<String, dynamic>> get timeline;
/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingCopyWith<Booking> get copyWith => _$BookingCopyWithImpl<Booking>(this as Booking, _$identity);

  /// Serializes this Booking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.offerPrice, offerPrice) || other.offerPrice == offerPrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.driverAvatar, driverAvatar) || other.driverAvatar == driverAvatar)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.message, message) || other.message == message)&&(identical(other.pickedUpAt, pickedUpAt) || other.pickedUpAt == pickedUpAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.goodsHandedBySenderAt, goodsHandedBySenderAt) || other.goodsHandedBySenderAt == goodsHandedBySenderAt)&&(identical(other.goodsReceivedByDriverAt, goodsReceivedByDriverAt) || other.goodsReceivedByDriverAt == goodsReceivedByDriverAt)&&(identical(other.paymentMarkedBySenderAt, paymentMarkedBySenderAt) || other.paymentMarkedBySenderAt == paymentMarkedBySenderAt)&&(identical(other.paymentConfirmedByDriverAt, paymentConfirmedByDriverAt) || other.paymentConfirmedByDriverAt == paymentConfirmedByDriverAt)&&(identical(other.goodsDeliveredByDriverAt, goodsDeliveredByDriverAt) || other.goodsDeliveredByDriverAt == goodsDeliveredByDriverAt)&&(identical(other.goodsReceivedByClientAt, goodsReceivedByClientAt) || other.goodsReceivedByClientAt == goodsReceivedByClientAt)&&(identical(other.deliveryCode, deliveryCode) || other.deliveryCode == deliveryCode)&&(identical(other.pickupPhotoUrl, pickupPhotoUrl) || other.pickupPhotoUrl == pickupPhotoUrl)&&(identical(other.deliveryPhotoUrl, deliveryPhotoUrl) || other.deliveryPhotoUrl == deliveryPhotoUrl)&&const DeepCollectionEquality().equals(other.timeline, timeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,driverId,offerPrice,status,createdAt,driverName,driverAvatar,senderId,tripId,requesterId,message,pickedUpAt,deliveredAt,paidAt,trip,driver,requester,goodsHandedBySenderAt,goodsReceivedByDriverAt,paymentMarkedBySenderAt,paymentConfirmedByDriverAt,goodsDeliveredByDriverAt,goodsReceivedByClientAt,deliveryCode,pickupPhotoUrl,deliveryPhotoUrl,const DeepCollectionEquality().hash(timeline)]);

@override
String toString() {
  return 'Booking(id: $id, driverId: $driverId, offerPrice: $offerPrice, status: $status, createdAt: $createdAt, driverName: $driverName, driverAvatar: $driverAvatar, senderId: $senderId, tripId: $tripId, requesterId: $requesterId, message: $message, pickedUpAt: $pickedUpAt, deliveredAt: $deliveredAt, paidAt: $paidAt, trip: $trip, driver: $driver, requester: $requester, goodsHandedBySenderAt: $goodsHandedBySenderAt, goodsReceivedByDriverAt: $goodsReceivedByDriverAt, paymentMarkedBySenderAt: $paymentMarkedBySenderAt, paymentConfirmedByDriverAt: $paymentConfirmedByDriverAt, goodsDeliveredByDriverAt: $goodsDeliveredByDriverAt, goodsReceivedByClientAt: $goodsReceivedByClientAt, deliveryCode: $deliveryCode, pickupPhotoUrl: $pickupPhotoUrl, deliveryPhotoUrl: $deliveryPhotoUrl, timeline: $timeline)';
}


}

/// @nodoc
abstract mixin class $BookingCopyWith<$Res>  {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) _then) = _$BookingCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'traveler_id') String driverId,@JsonKey(name: 'offer_price', readValue: _readOfferPrice) double offerPrice,@JsonKey(unknownEnumValue: BookingStatus.pending) BookingStatus status,@JsonKey(name: 'created_at') DateTime createdAt, String? driverName, String? driverAvatar, String? senderId,@JsonKey(name: 'trip_id') String? tripId,@JsonKey(name: 'requester_id') String? requesterId, String? message,@JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'paid_at') DateTime? paidAt,@JsonKey(name: 'trips') Trip? trip,@JsonKey(name: 'driver') Profile? driver,@JsonKey(name: 'requester') Profile? requester,@JsonKey(name: 'goods_handed_by_sender_at') DateTime? goodsHandedBySenderAt,@JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived) DateTime? goodsReceivedByDriverAt,@JsonKey(name: 'payment_marked_by_sender_at') DateTime? paymentMarkedBySenderAt,@JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed) DateTime? paymentConfirmedByDriverAt,@JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered) DateTime? goodsDeliveredByDriverAt,@JsonKey(name: 'goods_received_by_client_at') DateTime? goodsReceivedByClientAt,@JsonKey(name: 'delivery_code') String? deliveryCode,@JsonKey(name: 'pickup_photo_url') String? pickupPhotoUrl,@JsonKey(name: 'delivery_photo_url') String? deliveryPhotoUrl, List<Map<String, dynamic>> timeline
});


$TripCopyWith<$Res>? get trip;$ProfileCopyWith<$Res>? get driver;$ProfileCopyWith<$Res>? get requester;

}
/// @nodoc
class _$BookingCopyWithImpl<$Res>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._self, this._then);

  final Booking _self;
  final $Res Function(Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? driverId = null,Object? offerPrice = null,Object? status = null,Object? createdAt = null,Object? driverName = freezed,Object? driverAvatar = freezed,Object? senderId = freezed,Object? tripId = freezed,Object? requesterId = freezed,Object? message = freezed,Object? pickedUpAt = freezed,Object? deliveredAt = freezed,Object? paidAt = freezed,Object? trip = freezed,Object? driver = freezed,Object? requester = freezed,Object? goodsHandedBySenderAt = freezed,Object? goodsReceivedByDriverAt = freezed,Object? paymentMarkedBySenderAt = freezed,Object? paymentConfirmedByDriverAt = freezed,Object? goodsDeliveredByDriverAt = freezed,Object? goodsReceivedByClientAt = freezed,Object? deliveryCode = freezed,Object? pickupPhotoUrl = freezed,Object? deliveryPhotoUrl = freezed,Object? timeline = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,offerPrice: null == offerPrice ? _self.offerPrice : offerPrice // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,driverAvatar: freezed == driverAvatar ? _self.driverAvatar : driverAvatar // ignore: cast_nullable_to_non_nullable
as String?,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,requesterId: freezed == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,pickedUpAt: freezed == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,trip: freezed == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip?,driver: freezed == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as Profile?,requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as Profile?,goodsHandedBySenderAt: freezed == goodsHandedBySenderAt ? _self.goodsHandedBySenderAt : goodsHandedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByDriverAt: freezed == goodsReceivedByDriverAt ? _self.goodsReceivedByDriverAt : goodsReceivedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMarkedBySenderAt: freezed == paymentMarkedBySenderAt ? _self.paymentMarkedBySenderAt : paymentMarkedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentConfirmedByDriverAt: freezed == paymentConfirmedByDriverAt ? _self.paymentConfirmedByDriverAt : paymentConfirmedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsDeliveredByDriverAt: freezed == goodsDeliveredByDriverAt ? _self.goodsDeliveredByDriverAt : goodsDeliveredByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByClientAt: freezed == goodsReceivedByClientAt ? _self.goodsReceivedByClientAt : goodsReceivedByClientAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveryCode: freezed == deliveryCode ? _self.deliveryCode : deliveryCode // ignore: cast_nullable_to_non_nullable
as String?,pickupPhotoUrl: freezed == pickupPhotoUrl ? _self.pickupPhotoUrl : pickupPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,deliveryPhotoUrl: freezed == deliveryPhotoUrl ? _self.deliveryPhotoUrl : deliveryPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}
/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res>? get trip {
    if (_self.trip == null) {
    return null;
  }

  return $TripCopyWith<$Res>(_self.trip!, (value) {
    return _then(_self.copyWith(trip: value));
  });
}/// Create a copy of Booking
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
}/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get requester {
    if (_self.requester == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.requester!, (value) {
    return _then(_self.copyWith(requester: value));
  });
}
}


/// Adds pattern-matching-related methods to [Booking].
extension BookingPatterns on Booking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Booking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Booking value)  $default,){
final _that = this;
switch (_that) {
case _Booking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Booking value)?  $default,){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'traveler_id')  String driverId, @JsonKey(name: 'offer_price', readValue: _readOfferPrice)  double offerPrice, @JsonKey(unknownEnumValue: BookingStatus.pending)  BookingStatus status, @JsonKey(name: 'created_at')  DateTime createdAt,  String? driverName,  String? driverAvatar,  String? senderId, @JsonKey(name: 'trip_id')  String? tripId, @JsonKey(name: 'requester_id')  String? requesterId,  String? message, @JsonKey(name: 'picked_up_at')  DateTime? pickedUpAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'trips')  Trip? trip, @JsonKey(name: 'driver')  Profile? driver, @JsonKey(name: 'requester')  Profile? requester, @JsonKey(name: 'goods_handed_by_sender_at')  DateTime? goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived)  DateTime? goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at')  DateTime? paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed)  DateTime? paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered)  DateTime? goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at')  DateTime? goodsReceivedByClientAt, @JsonKey(name: 'delivery_code')  String? deliveryCode, @JsonKey(name: 'pickup_photo_url')  String? pickupPhotoUrl, @JsonKey(name: 'delivery_photo_url')  String? deliveryPhotoUrl,  List<Map<String, dynamic>> timeline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.driverId,_that.offerPrice,_that.status,_that.createdAt,_that.driverName,_that.driverAvatar,_that.senderId,_that.tripId,_that.requesterId,_that.message,_that.pickedUpAt,_that.deliveredAt,_that.paidAt,_that.trip,_that.driver,_that.requester,_that.goodsHandedBySenderAt,_that.goodsReceivedByDriverAt,_that.paymentMarkedBySenderAt,_that.paymentConfirmedByDriverAt,_that.goodsDeliveredByDriverAt,_that.goodsReceivedByClientAt,_that.deliveryCode,_that.pickupPhotoUrl,_that.deliveryPhotoUrl,_that.timeline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'traveler_id')  String driverId, @JsonKey(name: 'offer_price', readValue: _readOfferPrice)  double offerPrice, @JsonKey(unknownEnumValue: BookingStatus.pending)  BookingStatus status, @JsonKey(name: 'created_at')  DateTime createdAt,  String? driverName,  String? driverAvatar,  String? senderId, @JsonKey(name: 'trip_id')  String? tripId, @JsonKey(name: 'requester_id')  String? requesterId,  String? message, @JsonKey(name: 'picked_up_at')  DateTime? pickedUpAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'trips')  Trip? trip, @JsonKey(name: 'driver')  Profile? driver, @JsonKey(name: 'requester')  Profile? requester, @JsonKey(name: 'goods_handed_by_sender_at')  DateTime? goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived)  DateTime? goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at')  DateTime? paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed)  DateTime? paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered)  DateTime? goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at')  DateTime? goodsReceivedByClientAt, @JsonKey(name: 'delivery_code')  String? deliveryCode, @JsonKey(name: 'pickup_photo_url')  String? pickupPhotoUrl, @JsonKey(name: 'delivery_photo_url')  String? deliveryPhotoUrl,  List<Map<String, dynamic>> timeline)  $default,) {final _that = this;
switch (_that) {
case _Booking():
return $default(_that.id,_that.driverId,_that.offerPrice,_that.status,_that.createdAt,_that.driverName,_that.driverAvatar,_that.senderId,_that.tripId,_that.requesterId,_that.message,_that.pickedUpAt,_that.deliveredAt,_that.paidAt,_that.trip,_that.driver,_that.requester,_that.goodsHandedBySenderAt,_that.goodsReceivedByDriverAt,_that.paymentMarkedBySenderAt,_that.paymentConfirmedByDriverAt,_that.goodsDeliveredByDriverAt,_that.goodsReceivedByClientAt,_that.deliveryCode,_that.pickupPhotoUrl,_that.deliveryPhotoUrl,_that.timeline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'traveler_id')  String driverId, @JsonKey(name: 'offer_price', readValue: _readOfferPrice)  double offerPrice, @JsonKey(unknownEnumValue: BookingStatus.pending)  BookingStatus status, @JsonKey(name: 'created_at')  DateTime createdAt,  String? driverName,  String? driverAvatar,  String? senderId, @JsonKey(name: 'trip_id')  String? tripId, @JsonKey(name: 'requester_id')  String? requesterId,  String? message, @JsonKey(name: 'picked_up_at')  DateTime? pickedUpAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'trips')  Trip? trip, @JsonKey(name: 'driver')  Profile? driver, @JsonKey(name: 'requester')  Profile? requester, @JsonKey(name: 'goods_handed_by_sender_at')  DateTime? goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived)  DateTime? goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at')  DateTime? paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed)  DateTime? paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered)  DateTime? goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at')  DateTime? goodsReceivedByClientAt, @JsonKey(name: 'delivery_code')  String? deliveryCode, @JsonKey(name: 'pickup_photo_url')  String? pickupPhotoUrl, @JsonKey(name: 'delivery_photo_url')  String? deliveryPhotoUrl,  List<Map<String, dynamic>> timeline)?  $default,) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.driverId,_that.offerPrice,_that.status,_that.createdAt,_that.driverName,_that.driverAvatar,_that.senderId,_that.tripId,_that.requesterId,_that.message,_that.pickedUpAt,_that.deliveredAt,_that.paidAt,_that.trip,_that.driver,_that.requester,_that.goodsHandedBySenderAt,_that.goodsReceivedByDriverAt,_that.paymentMarkedBySenderAt,_that.paymentConfirmedByDriverAt,_that.goodsDeliveredByDriverAt,_that.goodsReceivedByClientAt,_that.deliveryCode,_that.pickupPhotoUrl,_that.deliveryPhotoUrl,_that.timeline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Booking extends Booking {
  const _Booking({required this.id, @JsonKey(name: 'traveler_id') required this.driverId, @JsonKey(name: 'offer_price', readValue: _readOfferPrice) required this.offerPrice, @JsonKey(unknownEnumValue: BookingStatus.pending) required this.status, @JsonKey(name: 'created_at') required this.createdAt, this.driverName, this.driverAvatar, this.senderId, @JsonKey(name: 'trip_id') this.tripId, @JsonKey(name: 'requester_id') this.requesterId, this.message, @JsonKey(name: 'picked_up_at') this.pickedUpAt, @JsonKey(name: 'delivered_at') this.deliveredAt, @JsonKey(name: 'paid_at') this.paidAt, @JsonKey(name: 'trips') this.trip, @JsonKey(name: 'driver') this.driver, @JsonKey(name: 'requester') this.requester, @JsonKey(name: 'goods_handed_by_sender_at') this.goodsHandedBySenderAt, @JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived) this.goodsReceivedByDriverAt, @JsonKey(name: 'payment_marked_by_sender_at') this.paymentMarkedBySenderAt, @JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed) this.paymentConfirmedByDriverAt, @JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered) this.goodsDeliveredByDriverAt, @JsonKey(name: 'goods_received_by_client_at') this.goodsReceivedByClientAt, @JsonKey(name: 'delivery_code') this.deliveryCode, @JsonKey(name: 'pickup_photo_url') this.pickupPhotoUrl, @JsonKey(name: 'delivery_photo_url') this.deliveryPhotoUrl, final  List<Map<String, dynamic>> timeline = const []}): _timeline = timeline,super._();
  factory _Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

@override final  String id;
@override@JsonKey(name: 'traveler_id') final  String driverId;
@override@JsonKey(name: 'offer_price', readValue: _readOfferPrice) final  double offerPrice;
@override@JsonKey(unknownEnumValue: BookingStatus.pending) final  BookingStatus status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
// Relations (flattened or nested depending on JOIN)
@override final  String? driverName;
@override final  String? driverAvatar;
@override final  String? senderId;
@override@JsonKey(name: 'trip_id') final  String? tripId;
@override@JsonKey(name: 'requester_id') final  String? requesterId;
@override final  String? message;
@override@JsonKey(name: 'picked_up_at') final  DateTime? pickedUpAt;
@override@JsonKey(name: 'delivered_at') final  DateTime? deliveredAt;
@override@JsonKey(name: 'paid_at') final  DateTime? paidAt;
@override@JsonKey(name: 'trips') final  Trip? trip;
@override@JsonKey(name: 'driver') final  Profile? driver;
@override@JsonKey(name: 'requester') final  Profile? requester;
// Lifecycle Handshake Timestamps
@override@JsonKey(name: 'goods_handed_by_sender_at') final  DateTime? goodsHandedBySenderAt;
@override@JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived) final  DateTime? goodsReceivedByDriverAt;
@override@JsonKey(name: 'payment_marked_by_sender_at') final  DateTime? paymentMarkedBySenderAt;
@override@JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed) final  DateTime? paymentConfirmedByDriverAt;
@override@JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered) final  DateTime? goodsDeliveredByDriverAt;
@override@JsonKey(name: 'goods_received_by_client_at') final  DateTime? goodsReceivedByClientAt;
@override@JsonKey(name: 'delivery_code') final  String? deliveryCode;
@override@JsonKey(name: 'pickup_photo_url') final  String? pickupPhotoUrl;
@override@JsonKey(name: 'delivery_photo_url') final  String? deliveryPhotoUrl;
 final  List<Map<String, dynamic>> _timeline;
@override@JsonKey() List<Map<String, dynamic>> get timeline {
  if (_timeline is EqualUnmodifiableListView) return _timeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeline);
}


/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingCopyWith<_Booking> get copyWith => __$BookingCopyWithImpl<_Booking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.offerPrice, offerPrice) || other.offerPrice == offerPrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.driverAvatar, driverAvatar) || other.driverAvatar == driverAvatar)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.message, message) || other.message == message)&&(identical(other.pickedUpAt, pickedUpAt) || other.pickedUpAt == pickedUpAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.goodsHandedBySenderAt, goodsHandedBySenderAt) || other.goodsHandedBySenderAt == goodsHandedBySenderAt)&&(identical(other.goodsReceivedByDriverAt, goodsReceivedByDriverAt) || other.goodsReceivedByDriverAt == goodsReceivedByDriverAt)&&(identical(other.paymentMarkedBySenderAt, paymentMarkedBySenderAt) || other.paymentMarkedBySenderAt == paymentMarkedBySenderAt)&&(identical(other.paymentConfirmedByDriverAt, paymentConfirmedByDriverAt) || other.paymentConfirmedByDriverAt == paymentConfirmedByDriverAt)&&(identical(other.goodsDeliveredByDriverAt, goodsDeliveredByDriverAt) || other.goodsDeliveredByDriverAt == goodsDeliveredByDriverAt)&&(identical(other.goodsReceivedByClientAt, goodsReceivedByClientAt) || other.goodsReceivedByClientAt == goodsReceivedByClientAt)&&(identical(other.deliveryCode, deliveryCode) || other.deliveryCode == deliveryCode)&&(identical(other.pickupPhotoUrl, pickupPhotoUrl) || other.pickupPhotoUrl == pickupPhotoUrl)&&(identical(other.deliveryPhotoUrl, deliveryPhotoUrl) || other.deliveryPhotoUrl == deliveryPhotoUrl)&&const DeepCollectionEquality().equals(other._timeline, _timeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,driverId,offerPrice,status,createdAt,driverName,driverAvatar,senderId,tripId,requesterId,message,pickedUpAt,deliveredAt,paidAt,trip,driver,requester,goodsHandedBySenderAt,goodsReceivedByDriverAt,paymentMarkedBySenderAt,paymentConfirmedByDriverAt,goodsDeliveredByDriverAt,goodsReceivedByClientAt,deliveryCode,pickupPhotoUrl,deliveryPhotoUrl,const DeepCollectionEquality().hash(_timeline)]);

@override
String toString() {
  return 'Booking(id: $id, driverId: $driverId, offerPrice: $offerPrice, status: $status, createdAt: $createdAt, driverName: $driverName, driverAvatar: $driverAvatar, senderId: $senderId, tripId: $tripId, requesterId: $requesterId, message: $message, pickedUpAt: $pickedUpAt, deliveredAt: $deliveredAt, paidAt: $paidAt, trip: $trip, driver: $driver, requester: $requester, goodsHandedBySenderAt: $goodsHandedBySenderAt, goodsReceivedByDriverAt: $goodsReceivedByDriverAt, paymentMarkedBySenderAt: $paymentMarkedBySenderAt, paymentConfirmedByDriverAt: $paymentConfirmedByDriverAt, goodsDeliveredByDriverAt: $goodsDeliveredByDriverAt, goodsReceivedByClientAt: $goodsReceivedByClientAt, deliveryCode: $deliveryCode, pickupPhotoUrl: $pickupPhotoUrl, deliveryPhotoUrl: $deliveryPhotoUrl, timeline: $timeline)';
}


}

/// @nodoc
abstract mixin class _$BookingCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$BookingCopyWith(_Booking value, $Res Function(_Booking) _then) = __$BookingCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'traveler_id') String driverId,@JsonKey(name: 'offer_price', readValue: _readOfferPrice) double offerPrice,@JsonKey(unknownEnumValue: BookingStatus.pending) BookingStatus status,@JsonKey(name: 'created_at') DateTime createdAt, String? driverName, String? driverAvatar, String? senderId,@JsonKey(name: 'trip_id') String? tripId,@JsonKey(name: 'requester_id') String? requesterId, String? message,@JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'paid_at') DateTime? paidAt,@JsonKey(name: 'trips') Trip? trip,@JsonKey(name: 'driver') Profile? driver,@JsonKey(name: 'requester') Profile? requester,@JsonKey(name: 'goods_handed_by_sender_at') DateTime? goodsHandedBySenderAt,@JsonKey(name: 'goods_received_by_traveler_at', readValue: _readGoodsReceived) DateTime? goodsReceivedByDriverAt,@JsonKey(name: 'payment_marked_by_sender_at') DateTime? paymentMarkedBySenderAt,@JsonKey(name: 'payment_confirmed_by_traveler_at', readValue: _readPaymentConfirmed) DateTime? paymentConfirmedByDriverAt,@JsonKey(name: 'goods_delivered_by_traveler_at', readValue: _readGoodsDelivered) DateTime? goodsDeliveredByDriverAt,@JsonKey(name: 'goods_received_by_client_at') DateTime? goodsReceivedByClientAt,@JsonKey(name: 'delivery_code') String? deliveryCode,@JsonKey(name: 'pickup_photo_url') String? pickupPhotoUrl,@JsonKey(name: 'delivery_photo_url') String? deliveryPhotoUrl, List<Map<String, dynamic>> timeline
});


@override $TripCopyWith<$Res>? get trip;@override $ProfileCopyWith<$Res>? get driver;@override $ProfileCopyWith<$Res>? get requester;

}
/// @nodoc
class __$BookingCopyWithImpl<$Res>
    implements _$BookingCopyWith<$Res> {
  __$BookingCopyWithImpl(this._self, this._then);

  final _Booking _self;
  final $Res Function(_Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? driverId = null,Object? offerPrice = null,Object? status = null,Object? createdAt = null,Object? driverName = freezed,Object? driverAvatar = freezed,Object? senderId = freezed,Object? tripId = freezed,Object? requesterId = freezed,Object? message = freezed,Object? pickedUpAt = freezed,Object? deliveredAt = freezed,Object? paidAt = freezed,Object? trip = freezed,Object? driver = freezed,Object? requester = freezed,Object? goodsHandedBySenderAt = freezed,Object? goodsReceivedByDriverAt = freezed,Object? paymentMarkedBySenderAt = freezed,Object? paymentConfirmedByDriverAt = freezed,Object? goodsDeliveredByDriverAt = freezed,Object? goodsReceivedByClientAt = freezed,Object? deliveryCode = freezed,Object? pickupPhotoUrl = freezed,Object? deliveryPhotoUrl = freezed,Object? timeline = null,}) {
  return _then(_Booking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,offerPrice: null == offerPrice ? _self.offerPrice : offerPrice // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,driverAvatar: freezed == driverAvatar ? _self.driverAvatar : driverAvatar // ignore: cast_nullable_to_non_nullable
as String?,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,requesterId: freezed == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,pickedUpAt: freezed == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,trip: freezed == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip?,driver: freezed == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as Profile?,requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as Profile?,goodsHandedBySenderAt: freezed == goodsHandedBySenderAt ? _self.goodsHandedBySenderAt : goodsHandedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByDriverAt: freezed == goodsReceivedByDriverAt ? _self.goodsReceivedByDriverAt : goodsReceivedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMarkedBySenderAt: freezed == paymentMarkedBySenderAt ? _self.paymentMarkedBySenderAt : paymentMarkedBySenderAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentConfirmedByDriverAt: freezed == paymentConfirmedByDriverAt ? _self.paymentConfirmedByDriverAt : paymentConfirmedByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsDeliveredByDriverAt: freezed == goodsDeliveredByDriverAt ? _self.goodsDeliveredByDriverAt : goodsDeliveredByDriverAt // ignore: cast_nullable_to_non_nullable
as DateTime?,goodsReceivedByClientAt: freezed == goodsReceivedByClientAt ? _self.goodsReceivedByClientAt : goodsReceivedByClientAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveryCode: freezed == deliveryCode ? _self.deliveryCode : deliveryCode // ignore: cast_nullable_to_non_nullable
as String?,pickupPhotoUrl: freezed == pickupPhotoUrl ? _self.pickupPhotoUrl : pickupPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,deliveryPhotoUrl: freezed == deliveryPhotoUrl ? _self.deliveryPhotoUrl : deliveryPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,timeline: null == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res>? get trip {
    if (_self.trip == null) {
    return null;
  }

  return $TripCopyWith<$Res>(_self.trip!, (value) {
    return _then(_self.copyWith(trip: value));
  });
}/// Create a copy of Booking
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
}/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get requester {
    if (_self.requester == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.requester!, (value) {
    return _then(_self.copyWith(requester: value));
  });
}
}

// dart format on
