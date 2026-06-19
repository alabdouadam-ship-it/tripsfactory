// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  fullName: json['full_name'] as String,
  phoneNumber: json['phone_number'] as String?,
  bio: json['bio'] as String?,
  accountType: json['account_type'] as String?,
  isAvailable: json['is_available'] as bool? ?? false,
  travelerStatus: json['traveler_status'] as String? ?? DomainConfig.statusNone,
  travelerType:
      json['traveler_type'] as String? ?? DomainConfig.travelerNoVehicle,
  identityType: json['identity_type'] as String? ?? DomainConfig.identityIdCard,
  identityDocUrl: json['identity_doc_url'] as String?,
  driverLicenseUrl: json['traveler_license_url'] as String?,
  rentalContractUrl: json['rental_contract_url'] as String?,
  companyStatus: json['company_status'] as String? ?? DomainConfig.statusNone,
  companyName: json['company_name'] as String?,
  companyAddress: json['company_address'] as String?,
  companyCrNumber: json['company_cr_number'] as String?,
  companyCrUrl: json['company_cr_url'] as String?,
  identityDocUrlPending: json['identity_doc_url_pending'] as String?,
  travelerLicenseUrlPending: json['traveler_license_url_pending'] as String?,
  rentalContractUrlPending: json['rental_contract_url_pending'] as String?,
  companyCrUrlPending: json['company_cr_url_pending'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  oneSignalPlayerId: json['onesignal_player_id'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  isSuspended: json['is_suspended'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
  subscriptionExpiresAt: json['subscription_expires_at'] == null
      ? null
      : DateTime.parse(json['subscription_expires_at'] as String),
  licenseExpiresAt: json['license_expires_at'] == null
      ? null
      : DateTime.parse(json['license_expires_at'] as String),
  travelerRatingAvg: _ratingFromJson(json['traveler_rating_avg']),
  travelerRatingCount: (json['traveler_rating_count'] as num?)?.toInt(),
  clientRatingAvg: _ratingFromJson(json['client_rating_avg']),
  clientRatingCount: (json['client_rating_count'] as num?)?.toInt(),
  isDriver: json['is_driver'] as bool? ?? false,
  companyValidityDate: json['company_validity_date'] == null
      ? null
      : DateTime.parse(json['company_validity_date'] as String),
  driverValidityDate: json['driver_validity_date'] == null
      ? null
      : DateTime.parse(json['driver_validity_date'] as String),
  avatarUpdatedAt: json['avatar_updated_at'] == null
      ? null
      : DateTime.parse(json['avatar_updated_at'] as String),
  isBlocked: json['is_blocked'] as bool? ?? false,
  suspensionReason: json['suspension_reason'] as String?,
  promotedUntil: json['promoted_until'] == null
      ? null
      : DateTime.parse(json['promoted_until'] as String),
  isTrusted: json['is_trusted'] as bool? ?? false,
  isFeatured: json['is_featured'] as bool? ?? false,
  trustBadge: json['trust_badge'] as String?,
  vehicles:
      (json['vehicles'] as List<dynamic>?)
          ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'phone_number': instance.phoneNumber,
  'bio': instance.bio,
  'account_type': instance.accountType,
  'is_available': instance.isAvailable,
  'traveler_status': instance.travelerStatus,
  'traveler_type': instance.travelerType,
  'identity_type': instance.identityType,
  'identity_doc_url': instance.identityDocUrl,
  'traveler_license_url': instance.driverLicenseUrl,
  'rental_contract_url': instance.rentalContractUrl,
  'company_status': instance.companyStatus,
  'company_name': instance.companyName,
  'company_address': instance.companyAddress,
  'company_cr_number': instance.companyCrNumber,
  'company_cr_url': instance.companyCrUrl,
  'identity_doc_url_pending': instance.identityDocUrlPending,
  'traveler_license_url_pending': instance.travelerLicenseUrlPending,
  'rental_contract_url_pending': instance.rentalContractUrlPending,
  'company_cr_url_pending': instance.companyCrUrlPending,
  'created_at': instance.createdAt?.toIso8601String(),
  'onesignal_player_id': instance.oneSignalPlayerId,
  'avatar_url': instance.avatarUrl,
  'is_suspended': instance.isSuspended,
  'is_admin': instance.isAdmin,
  'subscription_expires_at': instance.subscriptionExpiresAt?.toIso8601String(),
  'license_expires_at': instance.licenseExpiresAt?.toIso8601String(),
  'traveler_rating_avg': instance.travelerRatingAvg,
  'traveler_rating_count': instance.travelerRatingCount,
  'client_rating_avg': instance.clientRatingAvg,
  'client_rating_count': instance.clientRatingCount,
  'is_driver': instance.isDriver,
  'company_validity_date': instance.companyValidityDate?.toIso8601String(),
  'driver_validity_date': instance.driverValidityDate?.toIso8601String(),
  'avatar_updated_at': instance.avatarUpdatedAt?.toIso8601String(),
  'is_blocked': instance.isBlocked,
  'suspension_reason': instance.suspensionReason,
  'promoted_until': instance.promotedUntil?.toIso8601String(),
  'is_trusted': instance.isTrusted,
  'is_featured': instance.isFeatured,
  'trust_badge': instance.trustBadge,
  'vehicles': instance.vehicles,
};
