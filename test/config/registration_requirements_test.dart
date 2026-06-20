import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/config/registration_requirements.dart';

void main() {
  group('missingTravelerDoc — mirrors prior screen validation', () {
    // Helper with the "all present" defaults; override per case.
    MissingDocPrompt? call({
      bool isUpgrade = false,
      bool withVehicle = false,
      bool isVehicleRented = false,
      bool hasIdentity = true,
      bool hasLicense = true,
      bool hasVehiclePhoto = true,
      bool hasVehicleRegistration = true,
      bool hasRentalContract = true,
    }) {
      return RegistrationRequirements.missingTravelerDoc(
        isUpgrade: isUpgrade,
        withVehicle: withVehicle,
        isVehicleRented: isVehicleRented,
        hasIdentity: hasIdentity,
        hasLicense: hasLicense,
        hasVehiclePhoto: hasVehiclePhoto,
        hasVehicleRegistration: hasVehicleRegistration,
        hasRentalContract: hasRentalContract,
      );
    }

    test('identity required for non-upgrade simple traveler', () {
      expect(call(hasIdentity: false), MissingDocPrompt.identity);
    });

    test('simple traveler with identity passes', () {
      expect(call(), isNull);
    });

    test('upgrade skips the identity requirement', () {
      expect(
        call(isUpgrade: true, hasIdentity: false, withVehicle: false),
        isNull,
      );
    });

    test('identity takes precedence over vehicle docs', () {
      // Missing both identity and vehicle docs → identity prompt first.
      expect(
        call(withVehicle: true, hasIdentity: false, hasLicense: false),
        MissingDocPrompt.identity,
      );
    });

    test('with-vehicle: missing license → vehicleDocuments', () {
      expect(
        call(withVehicle: true, hasLicense: false),
        MissingDocPrompt.vehicleDocuments,
      );
    });

    test('with-vehicle: missing vehicle photo → vehicleDocuments', () {
      expect(
        call(withVehicle: true, hasVehiclePhoto: false),
        MissingDocPrompt.vehicleDocuments,
      );
    });

    test('with-vehicle: missing registration → vehicleDocuments', () {
      expect(
        call(withVehicle: true, hasVehicleRegistration: false),
        MissingDocPrompt.vehicleDocuments,
      );
    });

    test('with-vehicle, not rented, all vehicle docs present → passes', () {
      expect(call(withVehicle: true, isVehicleRented: false), isNull);
    });

    test('rented vehicle without rental contract → rentalContract', () {
      expect(
        call(
          withVehicle: true,
          isVehicleRented: true,
          hasRentalContract: false,
        ),
        MissingDocPrompt.rentalContract,
      );
    });

    test('rented vehicle with rental contract → passes', () {
      expect(call(withVehicle: true, isVehicleRented: true), isNull);
    });

    test('rental contract only checked after vehicle docs complete', () {
      // Missing a vehicle doc AND missing rental → vehicleDocuments wins.
      expect(
        call(
          withVehicle: true,
          isVehicleRented: true,
          hasLicense: false,
          hasRentalContract: false,
        ),
        MissingDocPrompt.vehicleDocuments,
      );
    });

    test('no-vehicle traveler ignores vehicle/rental docs', () {
      expect(
        call(
          withVehicle: false,
          hasLicense: false,
          hasVehiclePhoto: false,
          hasVehicleRegistration: false,
          isVehicleRented: true,
          hasRentalContract: false,
        ),
        isNull,
      );
    });
  });
}
