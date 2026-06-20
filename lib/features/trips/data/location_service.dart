import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/core/models/location_model.dart';

class LocationService {
  final SupabaseClient _client;

  LocationService(this._client);

  // Get unique Countries
  Future<List<Map<String, dynamic>>> getCountries() async {
    return _getUniqueLocationPart(
      columnAr: 'country_name_ar',
      columnEn: 'country_name_en',
      includeCountryCode: true,
    );
  }

  // Get Provinces for a Country
  Future<List<Map<String, dynamic>>> getProvinces(String countryNameAr) async {
    return _getUniqueLocationPart(
      columnAr: 'province_name_ar',
      columnEn: 'province_name_en',
      filterColumn: 'country_name_ar',
      filterValue: countryNameAr,
    );
  }

  // Get Cities for a Province
  Future<List<Map<String, dynamic>>> getCities(String provinceNameAr) async {
    return _getUniqueLocationPart(
      columnAr: 'city_name_ar',
      columnEn: 'city_name_en',
      filterColumn: 'province_name_ar',
      filterValue: provinceNameAr,
    );
  }

  // Generic Helper for fetching unique location parts
  Future<List<Map<String, dynamic>>> _getUniqueLocationPart({
    required String columnAr,
    required String columnEn,
    String? filterColumn,
    String? filterValue,
    bool includeCountryCode = false,
  }) async {
    final cols = includeCountryCode
        ? '$columnAr, $columnEn, country_code'
        : '$columnAr, $columnEn';
    var query = _client
        .from('locations')
        .select(cols)
        .eq('is_active', true);

    if (filterColumn != null && filterValue != null) {
      query = query.eq(filterColumn, filterValue);
    }

    final response = await query;
    final data = List<Map<String, dynamic>>.from(response);
    final unique = <String, Map<String, dynamic>>{};

    for (var item in data) {
      final key = '${item[columnAr]}_${item[columnEn]}';
      if (!unique.containsKey(key)) {
        unique[key] = {
          'name_ar': item[columnAr],
          'name_en': item[columnEn],
          if (includeCountryCode) 'country_code': item['country_code'],
        };
      }
    }
    return unique.values.toList();
  }

  // Get Towns for a City (This returns actual Location Rows with IDs)
  Future<List<Map<String, dynamic>>> getTowns(String cityNameAr) async {
    final response = await _client
        .from('locations')
        .select(
          'id, town_name_ar, town_name_en, city_name_ar, city_name_en',
        ) // Fetch ID here
        .eq('is_active', true)
        .eq('city_name_ar', cityNameAr);

    // Here we return the rows. Mapping 'town_name' to 'name' for compatibility
    return List<Map<String, dynamic>>.from(response).map((e) {
      return {
        'id': e['id'],
        'name_ar':
            e['town_name_ar'] ??
            e['city_name_ar'], // Fallback if town is null (shouldn't be if schema is strictly town-based rows)
        'name_en': e['town_name_en'] ?? e['city_name_en'],
      };
    }).toList();
  }

  // Generic fallback if needed, but prefer specific methods
  // Resolve a specific Location ID from the hierarchy
  Future<String?> findLocationId({
    required String countryAr,
    required String provinceAr,
    required String cityAr,
    String? townAr,
  }) async {
    var query = _client.from('locations').select('id').eq('is_active', true);

    // We match against AR names as they are the primary keys in our selection logic
    // (You could match EN as well, but AR is sufficient if consistent)
    query = query
        .eq('country_name_ar', countryAr)
        .eq('province_name_ar', provinceAr)
        .eq('city_name_ar', cityAr);

    if (townAr != null) {
      query = query.eq('town_name_ar', townAr);
    } else {
      // If town isn't specified, we try to find a "generic" row where town is null
      // OR just pick the first one if the user just cares about the city.
      // Ideally, we look for town_name_ar IS NULL.
      // But query.eq('town_name_ar', null) might not work directly in Dart client if it filters out everything.
      // filter('town_name_ar', 'is', null) is the way for null checks.
      query = query.filter('town_name_ar', 'is', null);
    }

    final response = await query.maybeSingle();

    if (response != null) {
      return response['id'].toString();
    }

    // Fallback: If we looked for a NULL town but found nothing, maybe the only rows have towns.
    // In that case, return *any* ID for that city so the FK constraint is satisfied.
    if (townAr == null) {
      final fallback = await _client
          .from('locations')
          .select('id')
          .eq('is_active', true)
          .eq('country_name_ar', countryAr)
          .eq('province_name_ar', provinceAr)
          .eq('city_name_ar', cityAr)
          .limit(1)
          .maybeSingle();
      return fallback?['id']?.toString();
    }

    return null;
  }

  Future<Location?> getLocationById(String id) async {
    final response = await _client
        .from('locations')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Location.fromJson(response);
  }
}

final locationServiceProvider = Provider(
  (ref) => LocationService(Supabase.instance.client),
);
