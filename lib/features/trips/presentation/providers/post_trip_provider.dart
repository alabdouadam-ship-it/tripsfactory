import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/core/config/geography_config.dart';
import 'package:tripsfactory/features/trips/data/location_service.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';

part 'post_trip_provider.freezed.dart';

@freezed
abstract class PostTripState with _$PostTripState {
  const factory PostTripState({
    @Default(TransportType.internal) TransportType transportType,
    Map<String, dynamic>? selectedOriginCountry,
    Map<String, dynamic>? selectedOriginProvince,
    Map<String, dynamic>? selectedOriginCity,
    Map<String, dynamic>? selectedOriginTown,
    Map<String, dynamic>? selectedDestCountry,
    Map<String, dynamic>? selectedDestProvince,
    Map<String, dynamic>? selectedDestCity,
    Map<String, dynamic>? selectedDestTown,
    @Default([]) List<Map<String, dynamic>> countries,
    @Default([]) List<Map<String, dynamic>> originProvinces,
    @Default([]) List<Map<String, dynamic>> originCities,
    @Default([]) List<Map<String, dynamic>> originTowns,
    @Default([]) List<Map<String, dynamic>> destProvinces,
    @Default([]) List<Map<String, dynamic>> destCities,
    @Default([]) List<Map<String, dynamic>> destTowns,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    @Default([]) List<DateTime> repeatDates,
    @Default(false) bool isSaving,
    @Default(false) bool isLoadingLocations,
  }) = _PostTripState;
}

class PostTripNotifier extends AutoDisposeNotifier<PostTripState> {
  @override
  PostTripState build() {
    // Initial data load is handled by calling initialize()
    return const PostTripState();
  }

  Future<void> initialize({Trip? initialTrip, String? transportMode}) async {
    state = state.copyWith(isLoadingLocations: true);

    final locService = ref.read(locationServiceProvider);
    final countries = await locService.getCountries();

    TransportType type = TransportType.internal;
    if (initialTrip != null) {
      type =
          Location.isExternalTrip(
            initialTrip.originLocation,
            initialTrip.destLocation,
          )
          ? TransportType.external
          : TransportType.internal;
    } else if (transportMode == 'external') {
      type = TransportType.external;
    }

    state = state.copyWith(countries: countries, transportType: type);

    if (initialTrip != null) {
      await _applyInitialTrip(initialTrip);
    } else if (type == TransportType.internal) {
      // Default both endpoints to the home country for internal routes.
      try {
        final home = countries.firstWhere(
          (c) => GeographyConfig.isHomeCountry(
            code: c['country_code'] as String?,
            nameEn: c['name_en'] as String?,
            nameAr: c['name_ar'] as String?,
          ),
        );
        state = state.copyWith(
          selectedOriginCountry: home,
          selectedDestCountry: home,
        );
        await _loadOriginProvinces();
        await _loadDestProvinces();
      } catch (e) {
        StructuredLogger.error(
          'PostTripNotifier',
          'Home country (${GeographyConfig.homeCountryNameEn}) not found in locations',
        );
      }
    }

    state = state.copyWith(isLoadingLocations: false);
  }

  Future<void> _applyInitialTrip(Trip trip) async {
    final locService = ref.read(locationServiceProvider);
    final origin = trip.originLocation;
    final dest = trip.destLocation;
    if (origin == null || dest == null) return;

    // Origin Match
    final countries = state.countries;
    final selectedOriginCountry = countries.firstWhere(
      (c) =>
          c['name_ar'] == origin.countryNameAr ||
          c['name_en'] == origin.countryNameEn,
      orElse: () => countries.first,
    );

    final originProvinces = await locService.getProvinces(
      selectedOriginCountry['name_ar'],
    );
    final selectedOriginProvince = originProvinces.firstWhere(
      (p) =>
          p['name_ar'] == origin.provinceNameAr ||
          p['name_en'] == origin.provinceNameEn,
      orElse: () => originProvinces.first,
    );

    final originCities = await locService.getCities(
      selectedOriginProvince['name_ar'],
    );
    final selectedOriginCity = originCities.firstWhere(
      (c) =>
          c['name_ar'] == origin.cityNameAr ||
          c['name_en'] == origin.cityNameEn,
      orElse: () => originCities.first,
    );

    final originTowns = await locService.getTowns(
      selectedOriginCity['name_ar'],
    );
    Map<String, dynamic>? selectedOriginTown;
    try {
      selectedOriginTown = originTowns.firstWhere(
        (t) => t['id']?.toString() == origin.id,
      );
    } catch (_) {}

    // Dest Match
    final selectedDestCountry = countries.firstWhere(
      (c) =>
          c['name_ar'] == dest.countryNameAr ||
          c['name_en'] == dest.countryNameEn,
      orElse: () => countries.first,
    );

    final destProvinces = await locService.getProvinces(
      selectedDestCountry['name_ar'],
    );
    final selectedDestProvince = destProvinces.firstWhere(
      (p) =>
          p['name_ar'] == dest.provinceNameAr ||
          p['name_en'] == dest.provinceNameEn,
      orElse: () => destProvinces.first,
    );

    final destCities = await locService.getCities(
      selectedDestProvince['name_ar'],
    );
    final selectedDestCity = destCities.firstWhere(
      (c) => c['name_ar'] == dest.cityNameAr || c['name_en'] == dest.cityNameEn,
      orElse: () => destCities.first,
    );

    final destTowns = await locService.getTowns(selectedDestCity['name_ar']);
    Map<String, dynamic>? selectedDestTown;
    try {
      selectedDestTown = destTowns.firstWhere(
        (t) => t['id']?.toString() == dest.id,
      );
    } catch (_) {}

    state = state.copyWith(
      selectedOriginCountry: selectedOriginCountry,
      selectedOriginProvince: selectedOriginProvince,
      selectedOriginCity: selectedOriginCity,
      selectedOriginTown: selectedOriginTown,
      originProvinces: originProvinces,
      originCities: originCities,
      originTowns: originTowns,
      selectedDestCountry: selectedDestCountry,
      selectedDestProvince: selectedDestProvince,
      selectedDestCity: selectedDestCity,
      selectedDestTown: selectedDestTown,
      destProvinces: destProvinces,
      destCities: destCities,
      destTowns: destTowns,
      selectedDate: trip.departureTime,
      selectedTime: TimeOfDay.fromDateTime(trip.departureTime),
    );
  }

  void setTransportType(TransportType type) {
    state = state.copyWith(
      transportType: type,
      selectedOriginCountry: null,
      selectedOriginProvince: null,
      selectedOriginCity: null,
      selectedOriginTown: null,
      selectedDestCountry: null,
      selectedDestProvince: null,
      selectedDestCity: null,
      selectedDestTown: null,
      originProvinces: [],
      originCities: [],
      originTowns: [],
      destProvinces: [],
      destCities: [],
      destTowns: [],
    );
    initialize(
      transportMode: type == TransportType.external ? 'external' : 'internal',
    );
  }

  Future<void> onOriginCountryChanged(Map<String, dynamic>? country) async {
    state = state.copyWith(
      selectedOriginCountry: country,
      selectedOriginProvince: null,
      selectedOriginCity: null,
      selectedOriginTown: null,
      originProvinces: [],
      originCities: [],
      originTowns: [],
    );
    if (country != null) await _loadOriginProvinces();
  }

  Future<void> _loadOriginProvinces() async {
    if (state.selectedOriginCountry == null) return;
    final provinces = await ref
        .read(locationServiceProvider)
        .getProvinces(state.selectedOriginCountry!['name_ar']);
    state = state.copyWith(originProvinces: provinces);
  }

  Future<void> onOriginProvinceChanged(Map<String, dynamic>? province) async {
    state = state.copyWith(
      selectedOriginProvince: province,
      selectedOriginCity: null,
      selectedOriginTown: null,
      originCities: [],
      originTowns: [],
    );
    if (province != null) {
      final cities = await ref
          .read(locationServiceProvider)
          .getCities(province['name_ar']);
      state = state.copyWith(originCities: cities);
    }
  }

  Future<void> onOriginCityChanged(Map<String, dynamic>? city) async {
    state = state.copyWith(
      selectedOriginCity: city,
      selectedOriginTown: null,
      originTowns: [],
    );
    if (city != null) {
      final towns = await ref
          .read(locationServiceProvider)
          .getTowns(city['name_ar']);
      state = state.copyWith(originTowns: towns);
    }
  }

  void onOriginTownChanged(Map<String, dynamic>? town) {
    state = state.copyWith(selectedOriginTown: town);
  }

  // Destination handlers
  Future<void> onDestCountryChanged(Map<String, dynamic>? country) async {
    state = state.copyWith(
      selectedDestCountry: country,
      selectedDestProvince: null,
      selectedDestCity: null,
      selectedDestTown: null,
      destProvinces: [],
      destCities: [],
      destTowns: [],
    );
    if (country != null) await _loadDestProvinces();
  }

  Future<void> _loadDestProvinces() async {
    if (state.selectedDestCountry == null) return;
    final provinces = await ref
        .read(locationServiceProvider)
        .getProvinces(state.selectedDestCountry!['name_ar']);
    state = state.copyWith(destProvinces: provinces);
  }

  Future<void> onDestProvinceChanged(Map<String, dynamic>? province) async {
    state = state.copyWith(
      selectedDestProvince: province,
      selectedDestCity: null,
      selectedDestTown: null,
      destCities: [],
      destTowns: [],
    );
    if (province != null) {
      final cities = await ref
          .read(locationServiceProvider)
          .getCities(province['name_ar']);
      state = state.copyWith(destCities: cities);
    }
  }

  Future<void> onDestCityChanged(Map<String, dynamic>? city) async {
    state = state.copyWith(
      selectedDestCity: city,
      selectedDestTown: null,
      destTowns: [],
    );
    if (city != null) {
      final towns = await ref
          .read(locationServiceProvider)
          .getTowns(city['name_ar']);
      state = state.copyWith(destTowns: towns);
    }
  }

  void onDestTownChanged(Map<String, dynamic>? town) {
    state = state.copyWith(selectedDestTown: town);
  }

  void onDateChanged(DateTime? date) =>
      state = state.copyWith(selectedDate: date);
  void onTimeChanged(TimeOfDay? time) =>
      state = state.copyWith(selectedTime: time);
  void onRepeatDatesChanged(List<DateTime> dates) =>
      state = state.copyWith(repeatDates: dates);

  Future<bool> submit({required double? weight, required String? notes}) async {
    if (state.selectedDate == null || state.selectedTime == null) return false;

    state = state.copyWith(isSaving: true);

    try {
      final departureTime = DateTime(
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        state.selectedTime!.hour,
        state.selectedTime!.minute,
      );

      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw TripsFactoryException.withKey('user_not_logged_in', 'User not logged in');
      }

      final locationService = ref.read(locationServiceProvider);

      // Resolve IDs
      String? originId =
          state.selectedOriginTown?['id']?.toString() ??
          await locationService.findLocationId(
            countryAr: state.selectedOriginCountry?['name_ar'],
            provinceAr: state.selectedOriginProvince?['name_ar'],
            cityAr: state.selectedOriginCity?['name_ar'],
          );

      String? destId =
          state.selectedDestTown?['id']?.toString() ??
          await locationService.findLocationId(
            countryAr: state.selectedDestCountry?['name_ar'],
            provinceAr: state.selectedDestProvince?['name_ar'],
            cityAr: state.selectedDestCity?['name_ar'],
          );

      if (originId == null || destId == null) {
        throw TripsFactoryException.withKey(
          'location_not_resolved',
          'Could not resolve location IDs',
        );
      }

      // Create trips
      final repository = ref.read(tripRepositoryProvider);

      final mainTripData = {
        'driverId': user.id,
        'originLocationId': originId,
        'destLocationId': destId,
        'departureTime': departureTime,
        'maxWeight': weight,
        'suggestedFlatPrice': 0.0,
        'notes': notes,
      };

      final mainResult = await repository.createTrip(mainTripData);
      mainResult.fold((_) {}, (error) => throw error);

      for (final repeatDate in state.repeatDates) {
        final repeatDepartureTime = DateTime(
          repeatDate.year,
          repeatDate.month,
          repeatDate.day,
          state.selectedTime!.hour,
          state.selectedTime!.minute,
        );
        final repeatResult = await repository.createTrip({
          ...mainTripData,
          'departureTime': repeatDepartureTime,
        });
        repeatResult.fold((_) {}, (error) => throw error);
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e, st) {
      StructuredLogger.error('PostTripNotifier', 'Error posting trip', e, st);
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final postTripProvider =
    AutoDisposeNotifierProvider<PostTripNotifier, PostTripState>(
      () => PostTripNotifier(),
    );
