import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tripship/core/config/geography_config.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

@freezed
abstract class Location with _$Location {
  const Location._();

  const factory Location({
    required String id,
    @JsonKey(name: 'province_name_en') required String provinceNameEn,
    @JsonKey(name: 'province_name_ar') required String provinceNameAr,
    @JsonKey(name: 'city_name_en') required String cityNameEn,
    @JsonKey(name: 'city_name_ar') required String cityNameAr,
    @JsonKey(name: 'town_name_en') String? townNameEn,
    @JsonKey(name: 'town_name_ar') String? townNameAr,
    @Default(0.0) double latitude,
    @Default(0.0) double longitude,
    @JsonKey(name: 'country_name_en') required String countryNameEn,
    @JsonKey(name: 'country_name_ar') required String countryNameAr,
    @JsonKey(name: 'country_code') String? countryCode,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  // Helpers for display
  String getLocalizedCity(String locale) =>
      _isArabic(locale) ? cityNameAr : cityNameEn;
  String getLocalizedProvince(String locale) =>
      _isArabic(locale) ? provinceNameAr : provinceNameEn;
  String getLocalizedCountry(String locale) =>
      _isArabic(locale) ? countryNameAr : countryNameEn;

  bool _isArabic(String locale) => locale == 'ar';

  /// Whether the given country names denote the configured home country
  /// (name-only fallback; prefer the [isHomeCountry] getter which uses the ISO
  /// code when available). Routed through [GeographyConfig].
  static bool isHomeCountryName(String? nameEn, String? nameAr) =>
      GeographyConfig.isHomeCountryName(nameEn, nameAr);

  /// Whether this location is in the configured home country — matched by ISO
  /// `country_code` when present, otherwise by country name.
  bool get isHomeCountry => GeographyConfig.isHomeCountry(
    code: countryCode,
    nameEn: countryNameEn,
    nameAr: countryNameAr,
  );

  String formatLabel(bool isArabic, {bool isExternal = false}) {
    List<String> parts = [];

    void addPart(String part) {
      if (part.isNotEmpty && (parts.isEmpty || parts.last != part)) {
        parts.add(part);
      }
    }

    if (isHomeCountry && !isExternal) {
      addPart(isArabic ? provinceNameAr : provinceNameEn);
      addPart(isArabic ? cityNameAr : cityNameEn);
      final town = isArabic ? townNameAr : townNameEn;
      if (town != null) addPart(town);
    } else {
      addPart(isArabic ? countryNameAr : countryNameEn);
      addPart(isArabic ? provinceNameAr : provinceNameEn);
      addPart(isArabic ? cityNameAr : cityNameEn);
    }

    return parts.join(', ');
  }

  static String formatLocationName(dynamic province, dynamic city) {
    final p = (province as String?)?.trim() ?? '';
    final c = (city as String?)?.trim() ?? '';
    if (p.isNotEmpty && c.isNotEmpty) return '$p — $c';
    return p.isNotEmpty ? p : c;
  }

  static bool isExternalTrip(Location? loc1, Location? loc2) {
    if (loc1 != null && !loc1.isHomeCountry) return true;
    if (loc2 != null && !loc2.isHomeCountry) return true;
    return false;
  }
}
