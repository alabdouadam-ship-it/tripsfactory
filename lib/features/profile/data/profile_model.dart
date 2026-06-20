import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripship/features/profile/data/vehicle_model.dart';
import 'package:tripship/core/config/domain_config.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

num? _ratingFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

@freezed
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    String? bio,
    @JsonKey(name: 'is_available') @Default(false) bool isAvailable,
    @JsonKey(name: 'traveler_status') @Default(DomainConfig.statusNone) String travelerStatus,
    @JsonKey(name: 'traveler_type') @Default(DomainConfig.travelerNoVehicle) String travelerType,
    @JsonKey(name: 'identity_type') @Default(DomainConfig.identityIdCard) String identityType,
    @JsonKey(name: 'identity_doc_url') String? identityDocUrl,
    @JsonKey(name: 'traveler_license_url') String? driverLicenseUrl,
    @JsonKey(name: 'rental_contract_url') String? rentalContractUrl,
    @JsonKey(name: 'identity_doc_url_pending') String? identityDocUrlPending,
    @JsonKey(name: 'traveler_license_url_pending')
    String? travelerLicenseUrlPending,
    @JsonKey(name: 'rental_contract_url_pending')
    String? rentalContractUrlPending,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'onesignal_player_id') String? oneSignalPlayerId,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_suspended') @Default(false) bool isSuspended,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'subscription_expires_at') DateTime? subscriptionExpiresAt,
    @JsonKey(name: 'license_expires_at') DateTime? licenseExpiresAt,
    @JsonKey(name: 'traveler_rating_avg', fromJson: _ratingFromJson)
    num? travelerRatingAvg,
    @JsonKey(name: 'traveler_rating_count') int? travelerRatingCount,
    @JsonKey(name: 'client_rating_avg', fromJson: _ratingFromJson)
    num? clientRatingAvg,
    @JsonKey(name: 'client_rating_count') int? clientRatingCount,
    @JsonKey(name: 'is_driver') @Default(false) bool isDriver,
    @JsonKey(name: 'driver_validity_date') DateTime? driverValidityDate,
    @JsonKey(name: 'avatar_updated_at') DateTime? avatarUpdatedAt,
    @JsonKey(name: 'is_blocked') @Default(false) bool isBlocked,
    @JsonKey(name: 'suspension_reason') String? suspensionReason,
    @JsonKey(name: 'promoted_until') DateTime? promotedUntil,
    @JsonKey(name: 'is_trusted') @Default(false) bool isTrusted,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'trust_badge') String? trustBadge,
    @Default([]) List<Vehicle> vehicles,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  bool get isDriverValid {
    if (travelerStatus != DomainConfig.statusApproved) return false;
    if (!isDriver) return false;
    if (driverValidityDate == null) return true;
    return driverValidityDate!.isAfter(DateTime.now());
  }

  bool get canUpdateAvatar {
    if (avatarUpdatedAt == null) return true;
    final diff = DateTime.now().difference(avatarUpdatedAt!);
    return diff.inDays >= 30;
  }

  int get daysUntilNextAvatarUpdate {
    if (avatarUpdatedAt == null) return 0;
    final diff = DateTime.now().difference(avatarUpdatedAt!);
    if (diff.inDays >= 30) return 0;
    return 30 - diff.inDays;
  }
}
