import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';

part 'offer_model.freezed.dart';
part 'offer_model.g.dart';

@freezed
abstract class Offer with _$Offer {
  const Offer._();

  const factory Offer({
    required String id,
    @JsonKey(name: 'shipment_id') required String shipmentId,
    @JsonKey(name: 'driver_id') required String driverId,
    required double price,
    @JsonKey(unknownEnumValue: OfferStatus.sent) required OfferStatus status,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    String? message,
    @Default({}) Map<String, dynamic> metadata,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,

    // Relations (from JOINs)
    @JsonKey(name: 'profiles') Profile? driver,
    @JsonKey(name: 'shipments') Shipment? shipment,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

  bool get isSent => status == OfferStatus.sent;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isTerminal =>
      status == OfferStatus.rejected ||
      status == OfferStatus.cancelled ||
      status == OfferStatus.accepted;
}
