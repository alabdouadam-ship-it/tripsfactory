import 'package:tripsfactory/core/config/demo_config.dart';
import 'package:tripsfactory/core/config/domain_config.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/features/profile/data/profile_model.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';

/// In-memory seed data used when [DemoConfig.enabled] is true.
///
/// Everything here is fictional. It exists purely so an evaluator can explore
/// the app without provisioning a backend.
class DemoData {
  DemoData._();

  // --- Locations (UAE home country + a couple of external) --------------------
  static final Location dubai = Location(
    id: 'demo-loc-dubai',
    provinceNameEn: 'Dubai',
    provinceNameAr: 'دبي',
    cityNameEn: 'Dubai',
    cityNameAr: 'دبي',
    latitude: 25.2048,
    longitude: 55.2708,
    countryNameEn: 'United Arab Emirates',
    countryNameAr: 'الإمارات العربية المتحدة',
    countryCode: 'AE',
  );

  static final Location abuDhabi = Location(
    id: 'demo-loc-abudhabi',
    provinceNameEn: 'Abu Dhabi',
    provinceNameAr: 'أبو ظبي',
    cityNameEn: 'Abu Dhabi',
    cityNameAr: 'أبو ظبي',
    latitude: 24.4539,
    longitude: 54.3773,
    countryNameEn: 'United Arab Emirates',
    countryNameAr: 'الإمارات العربية المتحدة',
    countryCode: 'AE',
  );

  static final Location sharjah = Location(
    id: 'demo-loc-sharjah',
    provinceNameEn: 'Sharjah',
    provinceNameAr: 'الشارقة',
    cityNameEn: 'Sharjah',
    cityNameAr: 'الشارقة',
    latitude: 25.3463,
    longitude: 55.4209,
    countryNameEn: 'United Arab Emirates',
    countryNameAr: 'الإمارات العربية المتحدة',
    countryCode: 'AE',
  );

  static final Location riyadh = Location(
    id: 'demo-loc-riyadh',
    provinceNameEn: 'Riyadh',
    provinceNameAr: 'الرياض',
    cityNameEn: 'Riyadh',
    cityNameAr: 'الرياض',
    latitude: 24.7136,
    longitude: 46.6753,
    countryNameEn: 'Saudi Arabia',
    countryNameAr: 'المملكة العربية السعودية',
    countryCode: 'SA',
  );

  static List<Location> get locations => [dubai, abuDhabi, sharjah, riyadh];

  // --- Profiles ---------------------------------------------------------------
  static final Profile currentUser = Profile(
    id: DemoConfig.demoUserId,
    fullName: 'Demo User',
    phoneNumber: '+971500000000',
    bio: 'Exploring TripsFactory in demo mode.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    clientRatingAvg: 4.8,
    clientRatingCount: 12,
    // Approved so demo can enter Driver mode.
    travelerStatus: DomainConfig.statusApproved,
    travelerType: DomainConfig.travelerWithVehicle,
    isDriver: true,
    travelerRatingAvg: 4.7,
    travelerRatingCount: 9,
    isTrusted: true,
  );

  static final Profile _driverSara = Profile(
    id: 'demo-driver-1',
    fullName: 'Sara Al Maktoum',
    isDriver: true,
    travelerRatingAvg: 4.9,
    travelerRatingCount: 47,
    isTrusted: true,
    createdAt: DateTime.now().subtract(const Duration(days: 120)),
  );

  static final Profile _driverOmar = Profile(
    id: 'demo-driver-2',
    fullName: 'Omar Haddad',
    isDriver: true,
    travelerRatingAvg: 4.6,
    travelerRatingCount: 23,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  );

  // --- Trips ------------------------------------------------------------------
  static List<Trip> get trips {
    final now = DateTime.now();
    return [
      Trip(
        id: 'demo-trip-1',
        driverId: _driverSara.id,
        originLocationId: dubai.id,
        destLocationId: abuDhabi.id,
        departureTime: now.add(const Duration(days: 1, hours: 3)),
        maxWeightKg: 25,
        suggestedFlatPrice: 60,
        status: TripStatus.available,
        createdAt: now.subtract(const Duration(hours: 5)),
        originLocation: dubai,
        destLocation: abuDhabi,
        driver: _driverSara,
        notes: 'Sedan with spare boot space. Fragile items welcome.',
      ),
      Trip(
        id: 'demo-trip-2',
        driverId: _driverOmar.id,
        originLocationId: sharjah.id,
        destLocationId: dubai.id,
        departureTime: now.add(const Duration(hours: 8)),
        maxWeightKg: 10,
        suggestedFlatPrice: 25,
        status: TripStatus.available,
        createdAt: now.subtract(const Duration(hours: 2)),
        originLocation: sharjah,
        destLocation: dubai,
        driver: _driverOmar,
        notes: 'Daily commute — small parcels only.',
      ),
      Trip(
        id: 'demo-trip-3',
        driverId: _driverSara.id,
        originLocationId: dubai.id,
        destLocationId: riyadh.id,
        departureTime: now.add(const Duration(days: 2)),
        maxWeightKg: 40,
        suggestedFlatPrice: 220,
        status: TripStatus.available,
        createdAt: now.subtract(const Duration(days: 1)),
        originLocation: dubai,
        destLocation: riyadh,
        driver: _driverSara,
        notes: 'Cross-border (UAE → KSA). Documents handled.',
      ),
    ];
  }

  /// Trips owned by the demo user (shown in the driver-mode "My Trips" tab).
  static List<Trip> get myTrips {
    final now = DateTime.now();
    return [
      Trip(
        id: 'demo-mytrip-1',
        driverId: DemoConfig.demoUserId,
        originLocationId: abuDhabi.id,
        destLocationId: dubai.id,
        departureTime: now.add(const Duration(days: 1)),
        maxWeightKg: 30,
        suggestedFlatPrice: 55,
        status: TripStatus.available,
        createdAt: now.subtract(const Duration(hours: 6)),
        originLocation: abuDhabi,
        destLocation: dubai,
        driver: currentUser,
        notes: 'My posted demo trip.',
      ),
    ];
  }

  // --- Fake offline session ---------------------------------------------------
  /// A self-contained session payload with a far-future expiry so
  /// `GoTrueClient.recoverSession` accepts it without any network call.
  static Map<String, dynamic> sessionJson() {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final createdAt =
        DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
    return {
      'access_token': 'demo-access-token',
      'token_type': 'bearer',
      'expires_in': 31536000, // 1 year
      'expires_at': nowSec + 31536000,
      'refresh_token': 'demo-refresh-token',
      'user': {
        'id': DemoConfig.demoUserId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'demo@tripsfactory.app',
        'email_confirmed_at': createdAt,
        'phone': '',
        'confirmed_at': createdAt,
        'last_sign_in_at': createdAt,
        'app_metadata': {
          'provider': 'email',
          'providers': ['email'],
        },
        'user_metadata': {'full_name': 'Demo User'},
        'identities': <dynamic>[],
        'created_at': createdAt,
        'updated_at': createdAt,
      },
    };
  }
}
