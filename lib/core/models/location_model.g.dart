// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Location _$LocationFromJson(Map<String, dynamic> json) => _Location(
  id: json['id'] as String,
  provinceNameEn: json['province_name_en'] as String,
  provinceNameAr: json['province_name_ar'] as String,
  cityNameEn: json['city_name_en'] as String,
  cityNameAr: json['city_name_ar'] as String,
  townNameEn: json['town_name_en'] as String?,
  townNameAr: json['town_name_ar'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
  longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
  countryNameEn: json['country_name_en'] as String,
  countryNameAr: json['country_name_ar'] as String,
  countryCode: json['country_code'] as String?,
);

Map<String, dynamic> _$LocationToJson(_Location instance) => <String, dynamic>{
  'id': instance.id,
  'province_name_en': instance.provinceNameEn,
  'province_name_ar': instance.provinceNameAr,
  'city_name_en': instance.cityNameEn,
  'city_name_ar': instance.cityNameAr,
  'town_name_en': instance.townNameEn,
  'town_name_ar': instance.townNameAr,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'country_name_en': instance.countryNameEn,
  'country_name_ar': instance.countryNameAr,
  'country_code': instance.countryCode,
};
