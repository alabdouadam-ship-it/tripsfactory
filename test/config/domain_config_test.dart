import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:tripship/core/config/app_constants.dart';

void main() {
  group('DomainConfig canonical values (DB contract)', () {
    // These values are persisted in / compared against Supabase columns.
    // Changing them is a backend-coordinated migration, NOT a free rename —
    // this test pins them so an accidental edit fails loudly.
    test('account types', () {
      expect(DomainConfig.accountIndividual, 'individual');
      expect(DomainConfig.accountCompany, 'company');
    });

    test('verification statuses', () {
      expect(DomainConfig.statusNone, 'none');
      expect(DomainConfig.statusPending, 'pending');
      expect(DomainConfig.statusApproved, 'approved');
      expect(DomainConfig.statusRejected, 'rejected');
      expect(DomainConfig.statusSuspended, 'suspended');
    });

    test('traveler types', () {
      expect(DomainConfig.travelerWithVehicle, 'with_vehicle');
      expect(DomainConfig.travelerNoVehicle, 'no_vehicle');
    });

    test('identity types', () {
      expect(DomainConfig.identityIdCard, 'id_card');
      expect(DomainConfig.identityPassport, 'passport');
      expect(DomainConfig.identityIqama, 'iqama');
    });

    test('booking roles', () {
      expect(DomainConfig.roleSender, 'sender');
      expect(DomainConfig.roleTraveler, 'traveler');
      expect(DomainConfig.roleClient, 'client');
      expect(DomainConfig.roleDriver, 'driver');
    });
  });

  group('AppConstants delegates roles to DomainConfig', () {
    test('role constants match', () {
      expect(AppConstants.roleSender, DomainConfig.roleSender);
      expect(AppConstants.roleTraveler, DomainConfig.roleTraveler);
      expect(AppConstants.roleClient, DomainConfig.roleClient);
    });
  });
}
