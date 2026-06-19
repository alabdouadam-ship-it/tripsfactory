// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {

 String get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'phone_number') String? get phoneNumber; String? get bio;@JsonKey(name: 'account_type') String? get accountType;@JsonKey(name: 'is_available') bool get isAvailable;@JsonKey(name: 'traveler_status') String get travelerStatus;@JsonKey(name: 'traveler_type') String get travelerType;@JsonKey(name: 'identity_type') String get identityType;@JsonKey(name: 'identity_doc_url') String? get identityDocUrl;@JsonKey(name: 'traveler_license_url') String? get driverLicenseUrl;@JsonKey(name: 'rental_contract_url') String? get rentalContractUrl;@JsonKey(name: 'company_status') String get companyStatus;@JsonKey(name: 'company_name') String? get companyName;@JsonKey(name: 'company_address') String? get companyAddress;@JsonKey(name: 'company_cr_number') String? get companyCrNumber;@JsonKey(name: 'company_cr_url') String? get companyCrUrl;@JsonKey(name: 'identity_doc_url_pending') String? get identityDocUrlPending;@JsonKey(name: 'traveler_license_url_pending') String? get travelerLicenseUrlPending;@JsonKey(name: 'rental_contract_url_pending') String? get rentalContractUrlPending;@JsonKey(name: 'company_cr_url_pending') String? get companyCrUrlPending;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'onesignal_player_id') String? get oneSignalPlayerId;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'is_suspended') bool get isSuspended;@JsonKey(name: 'is_admin') bool get isAdmin;@JsonKey(name: 'subscription_expires_at') DateTime? get subscriptionExpiresAt;@JsonKey(name: 'license_expires_at') DateTime? get licenseExpiresAt;@JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson) num? get travelerRatingAvg;@JsonKey(name: 'traveler_rating_count') int? get travelerRatingCount;@JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson) num? get clientRatingAvg;@JsonKey(name: 'client_rating_count') int? get clientRatingCount;@JsonKey(name: 'is_driver') bool get isDriver;@JsonKey(name: 'company_validity_date') DateTime? get companyValidityDate;@JsonKey(name: 'driver_validity_date') DateTime? get driverValidityDate;@JsonKey(name: 'avatar_updated_at') DateTime? get avatarUpdatedAt;@JsonKey(name: 'is_blocked') bool get isBlocked;@JsonKey(name: 'suspension_reason') String? get suspensionReason;@JsonKey(name: 'promoted_until') DateTime? get promotedUntil;@JsonKey(name: 'is_trusted') bool get isTrusted;@JsonKey(name: 'is_featured') bool get isFeatured;@JsonKey(name: 'trust_badge') String? get trustBadge; List<Vehicle> get vehicles;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.travelerStatus, travelerStatus) || other.travelerStatus == travelerStatus)&&(identical(other.travelerType, travelerType) || other.travelerType == travelerType)&&(identical(other.identityType, identityType) || other.identityType == identityType)&&(identical(other.identityDocUrl, identityDocUrl) || other.identityDocUrl == identityDocUrl)&&(identical(other.driverLicenseUrl, driverLicenseUrl) || other.driverLicenseUrl == driverLicenseUrl)&&(identical(other.rentalContractUrl, rentalContractUrl) || other.rentalContractUrl == rentalContractUrl)&&(identical(other.companyStatus, companyStatus) || other.companyStatus == companyStatus)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.companyAddress, companyAddress) || other.companyAddress == companyAddress)&&(identical(other.companyCrNumber, companyCrNumber) || other.companyCrNumber == companyCrNumber)&&(identical(other.companyCrUrl, companyCrUrl) || other.companyCrUrl == companyCrUrl)&&(identical(other.identityDocUrlPending, identityDocUrlPending) || other.identityDocUrlPending == identityDocUrlPending)&&(identical(other.travelerLicenseUrlPending, travelerLicenseUrlPending) || other.travelerLicenseUrlPending == travelerLicenseUrlPending)&&(identical(other.rentalContractUrlPending, rentalContractUrlPending) || other.rentalContractUrlPending == rentalContractUrlPending)&&(identical(other.companyCrUrlPending, companyCrUrlPending) || other.companyCrUrlPending == companyCrUrlPending)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.oneSignalPlayerId, oneSignalPlayerId) || other.oneSignalPlayerId == oneSignalPlayerId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isSuspended, isSuspended) || other.isSuspended == isSuspended)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.subscriptionExpiresAt, subscriptionExpiresAt) || other.subscriptionExpiresAt == subscriptionExpiresAt)&&(identical(other.licenseExpiresAt, licenseExpiresAt) || other.licenseExpiresAt == licenseExpiresAt)&&(identical(other.travelerRatingAvg, travelerRatingAvg) || other.travelerRatingAvg == travelerRatingAvg)&&(identical(other.travelerRatingCount, travelerRatingCount) || other.travelerRatingCount == travelerRatingCount)&&(identical(other.clientRatingAvg, clientRatingAvg) || other.clientRatingAvg == clientRatingAvg)&&(identical(other.clientRatingCount, clientRatingCount) || other.clientRatingCount == clientRatingCount)&&(identical(other.isDriver, isDriver) || other.isDriver == isDriver)&&(identical(other.companyValidityDate, companyValidityDate) || other.companyValidityDate == companyValidityDate)&&(identical(other.driverValidityDate, driverValidityDate) || other.driverValidityDate == driverValidityDate)&&(identical(other.avatarUpdatedAt, avatarUpdatedAt) || other.avatarUpdatedAt == avatarUpdatedAt)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.suspensionReason, suspensionReason) || other.suspensionReason == suspensionReason)&&(identical(other.promotedUntil, promotedUntil) || other.promotedUntil == promotedUntil)&&(identical(other.isTrusted, isTrusted) || other.isTrusted == isTrusted)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.trustBadge, trustBadge) || other.trustBadge == trustBadge)&&const DeepCollectionEquality().equals(other.vehicles, vehicles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,phoneNumber,bio,accountType,isAvailable,travelerStatus,travelerType,identityType,identityDocUrl,driverLicenseUrl,rentalContractUrl,companyStatus,companyName,companyAddress,companyCrNumber,companyCrUrl,identityDocUrlPending,travelerLicenseUrlPending,rentalContractUrlPending,companyCrUrlPending,createdAt,oneSignalPlayerId,avatarUrl,isSuspended,isAdmin,subscriptionExpiresAt,licenseExpiresAt,travelerRatingAvg,travelerRatingCount,clientRatingAvg,clientRatingCount,isDriver,companyValidityDate,driverValidityDate,avatarUpdatedAt,isBlocked,suspensionReason,promotedUntil,isTrusted,isFeatured,trustBadge,const DeepCollectionEquality().hash(vehicles)]);

@override
String toString() {
  return 'Profile(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, bio: $bio, accountType: $accountType, isAvailable: $isAvailable, travelerStatus: $travelerStatus, travelerType: $travelerType, identityType: $identityType, identityDocUrl: $identityDocUrl, driverLicenseUrl: $driverLicenseUrl, rentalContractUrl: $rentalContractUrl, companyStatus: $companyStatus, companyName: $companyName, companyAddress: $companyAddress, companyCrNumber: $companyCrNumber, companyCrUrl: $companyCrUrl, identityDocUrlPending: $identityDocUrlPending, travelerLicenseUrlPending: $travelerLicenseUrlPending, rentalContractUrlPending: $rentalContractUrlPending, companyCrUrlPending: $companyCrUrlPending, createdAt: $createdAt, oneSignalPlayerId: $oneSignalPlayerId, avatarUrl: $avatarUrl, isSuspended: $isSuspended, isAdmin: $isAdmin, subscriptionExpiresAt: $subscriptionExpiresAt, licenseExpiresAt: $licenseExpiresAt, travelerRatingAvg: $travelerRatingAvg, travelerRatingCount: $travelerRatingCount, clientRatingAvg: $clientRatingAvg, clientRatingCount: $clientRatingCount, isDriver: $isDriver, companyValidityDate: $companyValidityDate, driverValidityDate: $driverValidityDate, avatarUpdatedAt: $avatarUpdatedAt, isBlocked: $isBlocked, suspensionReason: $suspensionReason, promotedUntil: $promotedUntil, isTrusted: $isTrusted, isFeatured: $isFeatured, trustBadge: $trustBadge, vehicles: $vehicles)';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_number') String? phoneNumber, String? bio,@JsonKey(name: 'account_type') String? accountType,@JsonKey(name: 'is_available') bool isAvailable,@JsonKey(name: 'traveler_status') String travelerStatus,@JsonKey(name: 'traveler_type') String travelerType,@JsonKey(name: 'identity_type') String identityType,@JsonKey(name: 'identity_doc_url') String? identityDocUrl,@JsonKey(name: 'traveler_license_url') String? driverLicenseUrl,@JsonKey(name: 'rental_contract_url') String? rentalContractUrl,@JsonKey(name: 'company_status') String companyStatus,@JsonKey(name: 'company_name') String? companyName,@JsonKey(name: 'company_address') String? companyAddress,@JsonKey(name: 'company_cr_number') String? companyCrNumber,@JsonKey(name: 'company_cr_url') String? companyCrUrl,@JsonKey(name: 'identity_doc_url_pending') String? identityDocUrlPending,@JsonKey(name: 'traveler_license_url_pending') String? travelerLicenseUrlPending,@JsonKey(name: 'rental_contract_url_pending') String? rentalContractUrlPending,@JsonKey(name: 'company_cr_url_pending') String? companyCrUrlPending,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'onesignal_player_id') String? oneSignalPlayerId,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'is_suspended') bool isSuspended,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'subscription_expires_at') DateTime? subscriptionExpiresAt,@JsonKey(name: 'license_expires_at') DateTime? licenseExpiresAt,@JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson) num? travelerRatingAvg,@JsonKey(name: 'traveler_rating_count') int? travelerRatingCount,@JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson) num? clientRatingAvg,@JsonKey(name: 'client_rating_count') int? clientRatingCount,@JsonKey(name: 'is_driver') bool isDriver,@JsonKey(name: 'company_validity_date') DateTime? companyValidityDate,@JsonKey(name: 'driver_validity_date') DateTime? driverValidityDate,@JsonKey(name: 'avatar_updated_at') DateTime? avatarUpdatedAt,@JsonKey(name: 'is_blocked') bool isBlocked,@JsonKey(name: 'suspension_reason') String? suspensionReason,@JsonKey(name: 'promoted_until') DateTime? promotedUntil,@JsonKey(name: 'is_trusted') bool isTrusted,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'trust_badge') String? trustBadge, List<Vehicle> vehicles
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phoneNumber = freezed,Object? bio = freezed,Object? accountType = freezed,Object? isAvailable = null,Object? travelerStatus = null,Object? travelerType = null,Object? identityType = null,Object? identityDocUrl = freezed,Object? driverLicenseUrl = freezed,Object? rentalContractUrl = freezed,Object? companyStatus = null,Object? companyName = freezed,Object? companyAddress = freezed,Object? companyCrNumber = freezed,Object? companyCrUrl = freezed,Object? identityDocUrlPending = freezed,Object? travelerLicenseUrlPending = freezed,Object? rentalContractUrlPending = freezed,Object? companyCrUrlPending = freezed,Object? createdAt = freezed,Object? oneSignalPlayerId = freezed,Object? avatarUrl = freezed,Object? isSuspended = null,Object? isAdmin = null,Object? subscriptionExpiresAt = freezed,Object? licenseExpiresAt = freezed,Object? travelerRatingAvg = freezed,Object? travelerRatingCount = freezed,Object? clientRatingAvg = freezed,Object? clientRatingCount = freezed,Object? isDriver = null,Object? companyValidityDate = freezed,Object? driverValidityDate = freezed,Object? avatarUpdatedAt = freezed,Object? isBlocked = null,Object? suspensionReason = freezed,Object? promotedUntil = freezed,Object? isTrusted = null,Object? isFeatured = null,Object? trustBadge = freezed,Object? vehicles = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,accountType: freezed == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,travelerStatus: null == travelerStatus ? _self.travelerStatus : travelerStatus // ignore: cast_nullable_to_non_nullable
as String,travelerType: null == travelerType ? _self.travelerType : travelerType // ignore: cast_nullable_to_non_nullable
as String,identityType: null == identityType ? _self.identityType : identityType // ignore: cast_nullable_to_non_nullable
as String,identityDocUrl: freezed == identityDocUrl ? _self.identityDocUrl : identityDocUrl // ignore: cast_nullable_to_non_nullable
as String?,driverLicenseUrl: freezed == driverLicenseUrl ? _self.driverLicenseUrl : driverLicenseUrl // ignore: cast_nullable_to_non_nullable
as String?,rentalContractUrl: freezed == rentalContractUrl ? _self.rentalContractUrl : rentalContractUrl // ignore: cast_nullable_to_non_nullable
as String?,companyStatus: null == companyStatus ? _self.companyStatus : companyStatus // ignore: cast_nullable_to_non_nullable
as String,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,companyAddress: freezed == companyAddress ? _self.companyAddress : companyAddress // ignore: cast_nullable_to_non_nullable
as String?,companyCrNumber: freezed == companyCrNumber ? _self.companyCrNumber : companyCrNumber // ignore: cast_nullable_to_non_nullable
as String?,companyCrUrl: freezed == companyCrUrl ? _self.companyCrUrl : companyCrUrl // ignore: cast_nullable_to_non_nullable
as String?,identityDocUrlPending: freezed == identityDocUrlPending ? _self.identityDocUrlPending : identityDocUrlPending // ignore: cast_nullable_to_non_nullable
as String?,travelerLicenseUrlPending: freezed == travelerLicenseUrlPending ? _self.travelerLicenseUrlPending : travelerLicenseUrlPending // ignore: cast_nullable_to_non_nullable
as String?,rentalContractUrlPending: freezed == rentalContractUrlPending ? _self.rentalContractUrlPending : rentalContractUrlPending // ignore: cast_nullable_to_non_nullable
as String?,companyCrUrlPending: freezed == companyCrUrlPending ? _self.companyCrUrlPending : companyCrUrlPending // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,oneSignalPlayerId: freezed == oneSignalPlayerId ? _self.oneSignalPlayerId : oneSignalPlayerId // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isSuspended: null == isSuspended ? _self.isSuspended : isSuspended // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,subscriptionExpiresAt: freezed == subscriptionExpiresAt ? _self.subscriptionExpiresAt : subscriptionExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,licenseExpiresAt: freezed == licenseExpiresAt ? _self.licenseExpiresAt : licenseExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,travelerRatingAvg: freezed == travelerRatingAvg ? _self.travelerRatingAvg : travelerRatingAvg // ignore: cast_nullable_to_non_nullable
as num?,travelerRatingCount: freezed == travelerRatingCount ? _self.travelerRatingCount : travelerRatingCount // ignore: cast_nullable_to_non_nullable
as int?,clientRatingAvg: freezed == clientRatingAvg ? _self.clientRatingAvg : clientRatingAvg // ignore: cast_nullable_to_non_nullable
as num?,clientRatingCount: freezed == clientRatingCount ? _self.clientRatingCount : clientRatingCount // ignore: cast_nullable_to_non_nullable
as int?,isDriver: null == isDriver ? _self.isDriver : isDriver // ignore: cast_nullable_to_non_nullable
as bool,companyValidityDate: freezed == companyValidityDate ? _self.companyValidityDate : companyValidityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,driverValidityDate: freezed == driverValidityDate ? _self.driverValidityDate : driverValidityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,avatarUpdatedAt: freezed == avatarUpdatedAt ? _self.avatarUpdatedAt : avatarUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,suspensionReason: freezed == suspensionReason ? _self.suspensionReason : suspensionReason // ignore: cast_nullable_to_non_nullable
as String?,promotedUntil: freezed == promotedUntil ? _self.promotedUntil : promotedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isTrusted: null == isTrusted ? _self.isTrusted : isTrusted // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,trustBadge: freezed == trustBadge ? _self.trustBadge : trustBadge // ignore: cast_nullable_to_non_nullable
as String?,vehicles: null == vehicles ? _self.vehicles : vehicles // ignore: cast_nullable_to_non_nullable
as List<Vehicle>,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String? phoneNumber,  String? bio, @JsonKey(name: 'account_type')  String? accountType, @JsonKey(name: 'is_available')  bool isAvailable, @JsonKey(name: 'traveler_status')  String travelerStatus, @JsonKey(name: 'traveler_type')  String travelerType, @JsonKey(name: 'identity_type')  String identityType, @JsonKey(name: 'identity_doc_url')  String? identityDocUrl, @JsonKey(name: 'traveler_license_url')  String? driverLicenseUrl, @JsonKey(name: 'rental_contract_url')  String? rentalContractUrl, @JsonKey(name: 'company_status')  String companyStatus, @JsonKey(name: 'company_name')  String? companyName, @JsonKey(name: 'company_address')  String? companyAddress, @JsonKey(name: 'company_cr_number')  String? companyCrNumber, @JsonKey(name: 'company_cr_url')  String? companyCrUrl, @JsonKey(name: 'identity_doc_url_pending')  String? identityDocUrlPending, @JsonKey(name: 'traveler_license_url_pending')  String? travelerLicenseUrlPending, @JsonKey(name: 'rental_contract_url_pending')  String? rentalContractUrlPending, @JsonKey(name: 'company_cr_url_pending')  String? companyCrUrlPending, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'onesignal_player_id')  String? oneSignalPlayerId, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'is_suspended')  bool isSuspended, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'subscription_expires_at')  DateTime? subscriptionExpiresAt, @JsonKey(name: 'license_expires_at')  DateTime? licenseExpiresAt, @JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson)  num? travelerRatingAvg, @JsonKey(name: 'traveler_rating_count')  int? travelerRatingCount, @JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson)  num? clientRatingAvg, @JsonKey(name: 'client_rating_count')  int? clientRatingCount, @JsonKey(name: 'is_driver')  bool isDriver, @JsonKey(name: 'company_validity_date')  DateTime? companyValidityDate, @JsonKey(name: 'driver_validity_date')  DateTime? driverValidityDate, @JsonKey(name: 'avatar_updated_at')  DateTime? avatarUpdatedAt, @JsonKey(name: 'is_blocked')  bool isBlocked, @JsonKey(name: 'suspension_reason')  String? suspensionReason, @JsonKey(name: 'promoted_until')  DateTime? promotedUntil, @JsonKey(name: 'is_trusted')  bool isTrusted, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'trust_badge')  String? trustBadge,  List<Vehicle> vehicles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.bio,_that.accountType,_that.isAvailable,_that.travelerStatus,_that.travelerType,_that.identityType,_that.identityDocUrl,_that.driverLicenseUrl,_that.rentalContractUrl,_that.companyStatus,_that.companyName,_that.companyAddress,_that.companyCrNumber,_that.companyCrUrl,_that.identityDocUrlPending,_that.travelerLicenseUrlPending,_that.rentalContractUrlPending,_that.companyCrUrlPending,_that.createdAt,_that.oneSignalPlayerId,_that.avatarUrl,_that.isSuspended,_that.isAdmin,_that.subscriptionExpiresAt,_that.licenseExpiresAt,_that.travelerRatingAvg,_that.travelerRatingCount,_that.clientRatingAvg,_that.clientRatingCount,_that.isDriver,_that.companyValidityDate,_that.driverValidityDate,_that.avatarUpdatedAt,_that.isBlocked,_that.suspensionReason,_that.promotedUntil,_that.isTrusted,_that.isFeatured,_that.trustBadge,_that.vehicles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String? phoneNumber,  String? bio, @JsonKey(name: 'account_type')  String? accountType, @JsonKey(name: 'is_available')  bool isAvailable, @JsonKey(name: 'traveler_status')  String travelerStatus, @JsonKey(name: 'traveler_type')  String travelerType, @JsonKey(name: 'identity_type')  String identityType, @JsonKey(name: 'identity_doc_url')  String? identityDocUrl, @JsonKey(name: 'traveler_license_url')  String? driverLicenseUrl, @JsonKey(name: 'rental_contract_url')  String? rentalContractUrl, @JsonKey(name: 'company_status')  String companyStatus, @JsonKey(name: 'company_name')  String? companyName, @JsonKey(name: 'company_address')  String? companyAddress, @JsonKey(name: 'company_cr_number')  String? companyCrNumber, @JsonKey(name: 'company_cr_url')  String? companyCrUrl, @JsonKey(name: 'identity_doc_url_pending')  String? identityDocUrlPending, @JsonKey(name: 'traveler_license_url_pending')  String? travelerLicenseUrlPending, @JsonKey(name: 'rental_contract_url_pending')  String? rentalContractUrlPending, @JsonKey(name: 'company_cr_url_pending')  String? companyCrUrlPending, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'onesignal_player_id')  String? oneSignalPlayerId, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'is_suspended')  bool isSuspended, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'subscription_expires_at')  DateTime? subscriptionExpiresAt, @JsonKey(name: 'license_expires_at')  DateTime? licenseExpiresAt, @JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson)  num? travelerRatingAvg, @JsonKey(name: 'traveler_rating_count')  int? travelerRatingCount, @JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson)  num? clientRatingAvg, @JsonKey(name: 'client_rating_count')  int? clientRatingCount, @JsonKey(name: 'is_driver')  bool isDriver, @JsonKey(name: 'company_validity_date')  DateTime? companyValidityDate, @JsonKey(name: 'driver_validity_date')  DateTime? driverValidityDate, @JsonKey(name: 'avatar_updated_at')  DateTime? avatarUpdatedAt, @JsonKey(name: 'is_blocked')  bool isBlocked, @JsonKey(name: 'suspension_reason')  String? suspensionReason, @JsonKey(name: 'promoted_until')  DateTime? promotedUntil, @JsonKey(name: 'is_trusted')  bool isTrusted, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'trust_badge')  String? trustBadge,  List<Vehicle> vehicles)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.bio,_that.accountType,_that.isAvailable,_that.travelerStatus,_that.travelerType,_that.identityType,_that.identityDocUrl,_that.driverLicenseUrl,_that.rentalContractUrl,_that.companyStatus,_that.companyName,_that.companyAddress,_that.companyCrNumber,_that.companyCrUrl,_that.identityDocUrlPending,_that.travelerLicenseUrlPending,_that.rentalContractUrlPending,_that.companyCrUrlPending,_that.createdAt,_that.oneSignalPlayerId,_that.avatarUrl,_that.isSuspended,_that.isAdmin,_that.subscriptionExpiresAt,_that.licenseExpiresAt,_that.travelerRatingAvg,_that.travelerRatingCount,_that.clientRatingAvg,_that.clientRatingCount,_that.isDriver,_that.companyValidityDate,_that.driverValidityDate,_that.avatarUpdatedAt,_that.isBlocked,_that.suspensionReason,_that.promotedUntil,_that.isTrusted,_that.isFeatured,_that.trustBadge,_that.vehicles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String? phoneNumber,  String? bio, @JsonKey(name: 'account_type')  String? accountType, @JsonKey(name: 'is_available')  bool isAvailable, @JsonKey(name: 'traveler_status')  String travelerStatus, @JsonKey(name: 'traveler_type')  String travelerType, @JsonKey(name: 'identity_type')  String identityType, @JsonKey(name: 'identity_doc_url')  String? identityDocUrl, @JsonKey(name: 'traveler_license_url')  String? driverLicenseUrl, @JsonKey(name: 'rental_contract_url')  String? rentalContractUrl, @JsonKey(name: 'company_status')  String companyStatus, @JsonKey(name: 'company_name')  String? companyName, @JsonKey(name: 'company_address')  String? companyAddress, @JsonKey(name: 'company_cr_number')  String? companyCrNumber, @JsonKey(name: 'company_cr_url')  String? companyCrUrl, @JsonKey(name: 'identity_doc_url_pending')  String? identityDocUrlPending, @JsonKey(name: 'traveler_license_url_pending')  String? travelerLicenseUrlPending, @JsonKey(name: 'rental_contract_url_pending')  String? rentalContractUrlPending, @JsonKey(name: 'company_cr_url_pending')  String? companyCrUrlPending, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'onesignal_player_id')  String? oneSignalPlayerId, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'is_suspended')  bool isSuspended, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'subscription_expires_at')  DateTime? subscriptionExpiresAt, @JsonKey(name: 'license_expires_at')  DateTime? licenseExpiresAt, @JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson)  num? travelerRatingAvg, @JsonKey(name: 'traveler_rating_count')  int? travelerRatingCount, @JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson)  num? clientRatingAvg, @JsonKey(name: 'client_rating_count')  int? clientRatingCount, @JsonKey(name: 'is_driver')  bool isDriver, @JsonKey(name: 'company_validity_date')  DateTime? companyValidityDate, @JsonKey(name: 'driver_validity_date')  DateTime? driverValidityDate, @JsonKey(name: 'avatar_updated_at')  DateTime? avatarUpdatedAt, @JsonKey(name: 'is_blocked')  bool isBlocked, @JsonKey(name: 'suspension_reason')  String? suspensionReason, @JsonKey(name: 'promoted_until')  DateTime? promotedUntil, @JsonKey(name: 'is_trusted')  bool isTrusted, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'trust_badge')  String? trustBadge,  List<Vehicle> vehicles)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.bio,_that.accountType,_that.isAvailable,_that.travelerStatus,_that.travelerType,_that.identityType,_that.identityDocUrl,_that.driverLicenseUrl,_that.rentalContractUrl,_that.companyStatus,_that.companyName,_that.companyAddress,_that.companyCrNumber,_that.companyCrUrl,_that.identityDocUrlPending,_that.travelerLicenseUrlPending,_that.rentalContractUrlPending,_that.companyCrUrlPending,_that.createdAt,_that.oneSignalPlayerId,_that.avatarUrl,_that.isSuspended,_that.isAdmin,_that.subscriptionExpiresAt,_that.licenseExpiresAt,_that.travelerRatingAvg,_that.travelerRatingCount,_that.clientRatingAvg,_that.clientRatingCount,_that.isDriver,_that.companyValidityDate,_that.driverValidityDate,_that.avatarUpdatedAt,_that.isBlocked,_that.suspensionReason,_that.promotedUntil,_that.isTrusted,_that.isFeatured,_that.trustBadge,_that.vehicles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile extends Profile {
  const _Profile({required this.id, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'phone_number') this.phoneNumber, this.bio, @JsonKey(name: 'account_type') this.accountType, @JsonKey(name: 'is_available') this.isAvailable = false, @JsonKey(name: 'traveler_status') this.travelerStatus = DomainConfig.statusNone, @JsonKey(name: 'traveler_type') this.travelerType = DomainConfig.travelerNoVehicle, @JsonKey(name: 'identity_type') this.identityType = DomainConfig.identityIdCard, @JsonKey(name: 'identity_doc_url') this.identityDocUrl, @JsonKey(name: 'traveler_license_url') this.driverLicenseUrl, @JsonKey(name: 'rental_contract_url') this.rentalContractUrl, @JsonKey(name: 'company_status') this.companyStatus = DomainConfig.statusNone, @JsonKey(name: 'company_name') this.companyName, @JsonKey(name: 'company_address') this.companyAddress, @JsonKey(name: 'company_cr_number') this.companyCrNumber, @JsonKey(name: 'company_cr_url') this.companyCrUrl, @JsonKey(name: 'identity_doc_url_pending') this.identityDocUrlPending, @JsonKey(name: 'traveler_license_url_pending') this.travelerLicenseUrlPending, @JsonKey(name: 'rental_contract_url_pending') this.rentalContractUrlPending, @JsonKey(name: 'company_cr_url_pending') this.companyCrUrlPending, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'onesignal_player_id') this.oneSignalPlayerId, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'is_suspended') this.isSuspended = false, @JsonKey(name: 'is_admin') this.isAdmin = false, @JsonKey(name: 'subscription_expires_at') this.subscriptionExpiresAt, @JsonKey(name: 'license_expires_at') this.licenseExpiresAt, @JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson) this.travelerRatingAvg, @JsonKey(name: 'traveler_rating_count') this.travelerRatingCount, @JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson) this.clientRatingAvg, @JsonKey(name: 'client_rating_count') this.clientRatingCount, @JsonKey(name: 'is_driver') this.isDriver = false, @JsonKey(name: 'company_validity_date') this.companyValidityDate, @JsonKey(name: 'driver_validity_date') this.driverValidityDate, @JsonKey(name: 'avatar_updated_at') this.avatarUpdatedAt, @JsonKey(name: 'is_blocked') this.isBlocked = false, @JsonKey(name: 'suspension_reason') this.suspensionReason, @JsonKey(name: 'promoted_until') this.promotedUntil, @JsonKey(name: 'is_trusted') this.isTrusted = false, @JsonKey(name: 'is_featured') this.isFeatured = false, @JsonKey(name: 'trust_badge') this.trustBadge, final  List<Vehicle> vehicles = const []}): _vehicles = vehicles,super._();
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'phone_number') final  String? phoneNumber;
@override final  String? bio;
@override@JsonKey(name: 'account_type') final  String? accountType;
@override@JsonKey(name: 'is_available') final  bool isAvailable;
@override@JsonKey(name: 'traveler_status') final  String travelerStatus;
@override@JsonKey(name: 'traveler_type') final  String travelerType;
@override@JsonKey(name: 'identity_type') final  String identityType;
@override@JsonKey(name: 'identity_doc_url') final  String? identityDocUrl;
@override@JsonKey(name: 'traveler_license_url') final  String? driverLicenseUrl;
@override@JsonKey(name: 'rental_contract_url') final  String? rentalContractUrl;
@override@JsonKey(name: 'company_status') final  String companyStatus;
@override@JsonKey(name: 'company_name') final  String? companyName;
@override@JsonKey(name: 'company_address') final  String? companyAddress;
@override@JsonKey(name: 'company_cr_number') final  String? companyCrNumber;
@override@JsonKey(name: 'company_cr_url') final  String? companyCrUrl;
@override@JsonKey(name: 'identity_doc_url_pending') final  String? identityDocUrlPending;
@override@JsonKey(name: 'traveler_license_url_pending') final  String? travelerLicenseUrlPending;
@override@JsonKey(name: 'rental_contract_url_pending') final  String? rentalContractUrlPending;
@override@JsonKey(name: 'company_cr_url_pending') final  String? companyCrUrlPending;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'onesignal_player_id') final  String? oneSignalPlayerId;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'is_suspended') final  bool isSuspended;
@override@JsonKey(name: 'is_admin') final  bool isAdmin;
@override@JsonKey(name: 'subscription_expires_at') final  DateTime? subscriptionExpiresAt;
@override@JsonKey(name: 'license_expires_at') final  DateTime? licenseExpiresAt;
@override@JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson) final  num? travelerRatingAvg;
@override@JsonKey(name: 'traveler_rating_count') final  int? travelerRatingCount;
@override@JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson) final  num? clientRatingAvg;
@override@JsonKey(name: 'client_rating_count') final  int? clientRatingCount;
@override@JsonKey(name: 'is_driver') final  bool isDriver;
@override@JsonKey(name: 'company_validity_date') final  DateTime? companyValidityDate;
@override@JsonKey(name: 'driver_validity_date') final  DateTime? driverValidityDate;
@override@JsonKey(name: 'avatar_updated_at') final  DateTime? avatarUpdatedAt;
@override@JsonKey(name: 'is_blocked') final  bool isBlocked;
@override@JsonKey(name: 'suspension_reason') final  String? suspensionReason;
@override@JsonKey(name: 'promoted_until') final  DateTime? promotedUntil;
@override@JsonKey(name: 'is_trusted') final  bool isTrusted;
@override@JsonKey(name: 'is_featured') final  bool isFeatured;
@override@JsonKey(name: 'trust_badge') final  String? trustBadge;
 final  List<Vehicle> _vehicles;
@override@JsonKey() List<Vehicle> get vehicles {
  if (_vehicles is EqualUnmodifiableListView) return _vehicles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vehicles);
}


/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.travelerStatus, travelerStatus) || other.travelerStatus == travelerStatus)&&(identical(other.travelerType, travelerType) || other.travelerType == travelerType)&&(identical(other.identityType, identityType) || other.identityType == identityType)&&(identical(other.identityDocUrl, identityDocUrl) || other.identityDocUrl == identityDocUrl)&&(identical(other.driverLicenseUrl, driverLicenseUrl) || other.driverLicenseUrl == driverLicenseUrl)&&(identical(other.rentalContractUrl, rentalContractUrl) || other.rentalContractUrl == rentalContractUrl)&&(identical(other.companyStatus, companyStatus) || other.companyStatus == companyStatus)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.companyAddress, companyAddress) || other.companyAddress == companyAddress)&&(identical(other.companyCrNumber, companyCrNumber) || other.companyCrNumber == companyCrNumber)&&(identical(other.companyCrUrl, companyCrUrl) || other.companyCrUrl == companyCrUrl)&&(identical(other.identityDocUrlPending, identityDocUrlPending) || other.identityDocUrlPending == identityDocUrlPending)&&(identical(other.travelerLicenseUrlPending, travelerLicenseUrlPending) || other.travelerLicenseUrlPending == travelerLicenseUrlPending)&&(identical(other.rentalContractUrlPending, rentalContractUrlPending) || other.rentalContractUrlPending == rentalContractUrlPending)&&(identical(other.companyCrUrlPending, companyCrUrlPending) || other.companyCrUrlPending == companyCrUrlPending)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.oneSignalPlayerId, oneSignalPlayerId) || other.oneSignalPlayerId == oneSignalPlayerId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isSuspended, isSuspended) || other.isSuspended == isSuspended)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.subscriptionExpiresAt, subscriptionExpiresAt) || other.subscriptionExpiresAt == subscriptionExpiresAt)&&(identical(other.licenseExpiresAt, licenseExpiresAt) || other.licenseExpiresAt == licenseExpiresAt)&&(identical(other.travelerRatingAvg, travelerRatingAvg) || other.travelerRatingAvg == travelerRatingAvg)&&(identical(other.travelerRatingCount, travelerRatingCount) || other.travelerRatingCount == travelerRatingCount)&&(identical(other.clientRatingAvg, clientRatingAvg) || other.clientRatingAvg == clientRatingAvg)&&(identical(other.clientRatingCount, clientRatingCount) || other.clientRatingCount == clientRatingCount)&&(identical(other.isDriver, isDriver) || other.isDriver == isDriver)&&(identical(other.companyValidityDate, companyValidityDate) || other.companyValidityDate == companyValidityDate)&&(identical(other.driverValidityDate, driverValidityDate) || other.driverValidityDate == driverValidityDate)&&(identical(other.avatarUpdatedAt, avatarUpdatedAt) || other.avatarUpdatedAt == avatarUpdatedAt)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.suspensionReason, suspensionReason) || other.suspensionReason == suspensionReason)&&(identical(other.promotedUntil, promotedUntil) || other.promotedUntil == promotedUntil)&&(identical(other.isTrusted, isTrusted) || other.isTrusted == isTrusted)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.trustBadge, trustBadge) || other.trustBadge == trustBadge)&&const DeepCollectionEquality().equals(other._vehicles, _vehicles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,phoneNumber,bio,accountType,isAvailable,travelerStatus,travelerType,identityType,identityDocUrl,driverLicenseUrl,rentalContractUrl,companyStatus,companyName,companyAddress,companyCrNumber,companyCrUrl,identityDocUrlPending,travelerLicenseUrlPending,rentalContractUrlPending,companyCrUrlPending,createdAt,oneSignalPlayerId,avatarUrl,isSuspended,isAdmin,subscriptionExpiresAt,licenseExpiresAt,travelerRatingAvg,travelerRatingCount,clientRatingAvg,clientRatingCount,isDriver,companyValidityDate,driverValidityDate,avatarUpdatedAt,isBlocked,suspensionReason,promotedUntil,isTrusted,isFeatured,trustBadge,const DeepCollectionEquality().hash(_vehicles)]);

@override
String toString() {
  return 'Profile(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, bio: $bio, accountType: $accountType, isAvailable: $isAvailable, travelerStatus: $travelerStatus, travelerType: $travelerType, identityType: $identityType, identityDocUrl: $identityDocUrl, driverLicenseUrl: $driverLicenseUrl, rentalContractUrl: $rentalContractUrl, companyStatus: $companyStatus, companyName: $companyName, companyAddress: $companyAddress, companyCrNumber: $companyCrNumber, companyCrUrl: $companyCrUrl, identityDocUrlPending: $identityDocUrlPending, travelerLicenseUrlPending: $travelerLicenseUrlPending, rentalContractUrlPending: $rentalContractUrlPending, companyCrUrlPending: $companyCrUrlPending, createdAt: $createdAt, oneSignalPlayerId: $oneSignalPlayerId, avatarUrl: $avatarUrl, isSuspended: $isSuspended, isAdmin: $isAdmin, subscriptionExpiresAt: $subscriptionExpiresAt, licenseExpiresAt: $licenseExpiresAt, travelerRatingAvg: $travelerRatingAvg, travelerRatingCount: $travelerRatingCount, clientRatingAvg: $clientRatingAvg, clientRatingCount: $clientRatingCount, isDriver: $isDriver, companyValidityDate: $companyValidityDate, driverValidityDate: $driverValidityDate, avatarUpdatedAt: $avatarUpdatedAt, isBlocked: $isBlocked, suspensionReason: $suspensionReason, promotedUntil: $promotedUntil, isTrusted: $isTrusted, isFeatured: $isFeatured, trustBadge: $trustBadge, vehicles: $vehicles)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_number') String? phoneNumber, String? bio,@JsonKey(name: 'account_type') String? accountType,@JsonKey(name: 'is_available') bool isAvailable,@JsonKey(name: 'traveler_status') String travelerStatus,@JsonKey(name: 'traveler_type') String travelerType,@JsonKey(name: 'identity_type') String identityType,@JsonKey(name: 'identity_doc_url') String? identityDocUrl,@JsonKey(name: 'traveler_license_url') String? driverLicenseUrl,@JsonKey(name: 'rental_contract_url') String? rentalContractUrl,@JsonKey(name: 'company_status') String companyStatus,@JsonKey(name: 'company_name') String? companyName,@JsonKey(name: 'company_address') String? companyAddress,@JsonKey(name: 'company_cr_number') String? companyCrNumber,@JsonKey(name: 'company_cr_url') String? companyCrUrl,@JsonKey(name: 'identity_doc_url_pending') String? identityDocUrlPending,@JsonKey(name: 'traveler_license_url_pending') String? travelerLicenseUrlPending,@JsonKey(name: 'rental_contract_url_pending') String? rentalContractUrlPending,@JsonKey(name: 'company_cr_url_pending') String? companyCrUrlPending,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'onesignal_player_id') String? oneSignalPlayerId,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'is_suspended') bool isSuspended,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'subscription_expires_at') DateTime? subscriptionExpiresAt,@JsonKey(name: 'license_expires_at') DateTime? licenseExpiresAt,@JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson) num? travelerRatingAvg,@JsonKey(name: 'traveler_rating_count') int? travelerRatingCount,@JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson) num? clientRatingAvg,@JsonKey(name: 'client_rating_count') int? clientRatingCount,@JsonKey(name: 'is_driver') bool isDriver,@JsonKey(name: 'company_validity_date') DateTime? companyValidityDate,@JsonKey(name: 'driver_validity_date') DateTime? driverValidityDate,@JsonKey(name: 'avatar_updated_at') DateTime? avatarUpdatedAt,@JsonKey(name: 'is_blocked') bool isBlocked,@JsonKey(name: 'suspension_reason') String? suspensionReason,@JsonKey(name: 'promoted_until') DateTime? promotedUntil,@JsonKey(name: 'is_trusted') bool isTrusted,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'trust_badge') String? trustBadge, List<Vehicle> vehicles
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phoneNumber = freezed,Object? bio = freezed,Object? accountType = freezed,Object? isAvailable = null,Object? travelerStatus = null,Object? travelerType = null,Object? identityType = null,Object? identityDocUrl = freezed,Object? driverLicenseUrl = freezed,Object? rentalContractUrl = freezed,Object? companyStatus = null,Object? companyName = freezed,Object? companyAddress = freezed,Object? companyCrNumber = freezed,Object? companyCrUrl = freezed,Object? identityDocUrlPending = freezed,Object? travelerLicenseUrlPending = freezed,Object? rentalContractUrlPending = freezed,Object? companyCrUrlPending = freezed,Object? createdAt = freezed,Object? oneSignalPlayerId = freezed,Object? avatarUrl = freezed,Object? isSuspended = null,Object? isAdmin = null,Object? subscriptionExpiresAt = freezed,Object? licenseExpiresAt = freezed,Object? travelerRatingAvg = freezed,Object? travelerRatingCount = freezed,Object? clientRatingAvg = freezed,Object? clientRatingCount = freezed,Object? isDriver = null,Object? companyValidityDate = freezed,Object? driverValidityDate = freezed,Object? avatarUpdatedAt = freezed,Object? isBlocked = null,Object? suspensionReason = freezed,Object? promotedUntil = freezed,Object? isTrusted = null,Object? isFeatured = null,Object? trustBadge = freezed,Object? vehicles = null,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,accountType: freezed == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,travelerStatus: null == travelerStatus ? _self.travelerStatus : travelerStatus // ignore: cast_nullable_to_non_nullable
as String,travelerType: null == travelerType ? _self.travelerType : travelerType // ignore: cast_nullable_to_non_nullable
as String,identityType: null == identityType ? _self.identityType : identityType // ignore: cast_nullable_to_non_nullable
as String,identityDocUrl: freezed == identityDocUrl ? _self.identityDocUrl : identityDocUrl // ignore: cast_nullable_to_non_nullable
as String?,driverLicenseUrl: freezed == driverLicenseUrl ? _self.driverLicenseUrl : driverLicenseUrl // ignore: cast_nullable_to_non_nullable
as String?,rentalContractUrl: freezed == rentalContractUrl ? _self.rentalContractUrl : rentalContractUrl // ignore: cast_nullable_to_non_nullable
as String?,companyStatus: null == companyStatus ? _self.companyStatus : companyStatus // ignore: cast_nullable_to_non_nullable
as String,companyName: freezed == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String?,companyAddress: freezed == companyAddress ? _self.companyAddress : companyAddress // ignore: cast_nullable_to_non_nullable
as String?,companyCrNumber: freezed == companyCrNumber ? _self.companyCrNumber : companyCrNumber // ignore: cast_nullable_to_non_nullable
as String?,companyCrUrl: freezed == companyCrUrl ? _self.companyCrUrl : companyCrUrl // ignore: cast_nullable_to_non_nullable
as String?,identityDocUrlPending: freezed == identityDocUrlPending ? _self.identityDocUrlPending : identityDocUrlPending // ignore: cast_nullable_to_non_nullable
as String?,travelerLicenseUrlPending: freezed == travelerLicenseUrlPending ? _self.travelerLicenseUrlPending : travelerLicenseUrlPending // ignore: cast_nullable_to_non_nullable
as String?,rentalContractUrlPending: freezed == rentalContractUrlPending ? _self.rentalContractUrlPending : rentalContractUrlPending // ignore: cast_nullable_to_non_nullable
as String?,companyCrUrlPending: freezed == companyCrUrlPending ? _self.companyCrUrlPending : companyCrUrlPending // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,oneSignalPlayerId: freezed == oneSignalPlayerId ? _self.oneSignalPlayerId : oneSignalPlayerId // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isSuspended: null == isSuspended ? _self.isSuspended : isSuspended // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,subscriptionExpiresAt: freezed == subscriptionExpiresAt ? _self.subscriptionExpiresAt : subscriptionExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,licenseExpiresAt: freezed == licenseExpiresAt ? _self.licenseExpiresAt : licenseExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,travelerRatingAvg: freezed == travelerRatingAvg ? _self.travelerRatingAvg : travelerRatingAvg // ignore: cast_nullable_to_non_nullable
as num?,travelerRatingCount: freezed == travelerRatingCount ? _self.travelerRatingCount : travelerRatingCount // ignore: cast_nullable_to_non_nullable
as int?,clientRatingAvg: freezed == clientRatingAvg ? _self.clientRatingAvg : clientRatingAvg // ignore: cast_nullable_to_non_nullable
as num?,clientRatingCount: freezed == clientRatingCount ? _self.clientRatingCount : clientRatingCount // ignore: cast_nullable_to_non_nullable
as int?,isDriver: null == isDriver ? _self.isDriver : isDriver // ignore: cast_nullable_to_non_nullable
as bool,companyValidityDate: freezed == companyValidityDate ? _self.companyValidityDate : companyValidityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,driverValidityDate: freezed == driverValidityDate ? _self.driverValidityDate : driverValidityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,avatarUpdatedAt: freezed == avatarUpdatedAt ? _self.avatarUpdatedAt : avatarUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,suspensionReason: freezed == suspensionReason ? _self.suspensionReason : suspensionReason // ignore: cast_nullable_to_non_nullable
as String?,promotedUntil: freezed == promotedUntil ? _self.promotedUntil : promotedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isTrusted: null == isTrusted ? _self.isTrusted : isTrusted // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,trustBadge: freezed == trustBadge ? _self.trustBadge : trustBadge // ignore: cast_nullable_to_non_nullable
as String?,vehicles: null == vehicles ? _self._vehicles : vehicles // ignore: cast_nullable_to_non_nullable
as List<Vehicle>,
  ));
}


}

// dart format on
