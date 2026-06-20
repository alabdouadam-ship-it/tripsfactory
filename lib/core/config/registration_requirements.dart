/// Declarative registration document requirements — the fork seam for "what
/// documents must a role provide to apply".
///
/// The logic here is a faithful, side-effect-free extraction of the validators
/// that previously lived inline in the traveler registration screen.
/// It returns *which* prompt to show (a [MissingDocPrompt]); the screens map
/// that to a localized message, keeping copy in the ARB layer.
///
/// A fork that re-orients the domain (e.g. ride-share, services) changes the
/// required-document policy here in one place instead of editing screen
/// validators.
library;

/// Identifies which "please upload X" prompt a screen should show. Mirrors the
/// existing localized messages 1:1 (kept in the screens):
///   identity         → pleaseUploadIdentityProof
///   vehicleDocuments → pleaseUploadVehicleDocuments
///   rentalContract   → pleaseUploadRentalContract
enum MissingDocPrompt { identity, vehicleDocuments, rentalContract }

class RegistrationRequirements {
  RegistrationRequirements._();

  /// Traveler / driver application requirement check.
  ///
  /// Returns the first unmet requirement (in display-priority order) or null
  /// when all required documents are present. This is an exact mirror of the
  /// previous inline validation in `TravelerRegistrationScreen._submit`:
  ///   1. identity is required unless this is an upgrade,
  ///   2. with-vehicle travelers must provide license + vehicle photo +
  ///      registration (one grouped prompt),
  ///   3. a rented vehicle additionally requires a rental contract.
  static MissingDocPrompt? missingTravelerDoc({
    required bool isUpgrade,
    required bool withVehicle,
    required bool isVehicleRented,
    required bool hasIdentity,
    required bool hasLicense,
    required bool hasVehiclePhoto,
    required bool hasVehicleRegistration,
    required bool hasRentalContract,
  }) {
    if (!isUpgrade && !hasIdentity) return MissingDocPrompt.identity;

    if (withVehicle) {
      if (!hasLicense || !hasVehiclePhoto || !hasVehicleRegistration) {
        return MissingDocPrompt.vehicleDocuments;
      }
      if (isVehicleRented && !hasRentalContract) {
        return MissingDocPrompt.rentalContract;
      }
    }

    return null;
  }
}
