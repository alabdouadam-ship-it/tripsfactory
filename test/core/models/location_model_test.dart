import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/models/location_model.dart';

void main() {
  group('Location.fromJson', () {
    test('parses minimal valid json', () {
      final json = {
        'id': 'loc1',
        'province_name_en': 'Dubai',
        'province_name_ar': 'دبي',
        'city_name_en': 'Dubai',
        'city_name_ar': 'دبي',
        'latitude': 25.2048,
        'longitude': 55.2708,
        'country_name_en': 'United Arab Emirates',
        'country_name_ar': 'الإمارات العربية المتحدة',
      };
      final loc = Location.fromJson(json);
      expect(loc.id, 'loc1');
      expect(loc.cityNameEn, 'Dubai');
      expect(loc.cityNameAr, 'دبي');
      expect(loc.latitude, 25.2048);
      expect(loc.longitude, 55.2708);
      expect(loc.countryNameEn, 'United Arab Emirates');
    });

    test('formatLabel for internal (home country)', () {
      final loc = Location(
        id: '1',
        provinceNameEn: 'Dubai',
        provinceNameAr: 'دبي',
        cityNameEn: 'Deira',
        cityNameAr: 'ديرة',
        latitude: 25.2048,
        longitude: 55.2708,
        countryNameEn: 'United Arab Emirates',
        countryNameAr: 'الإمارات العربية المتحدة',
      );
      expect(loc.formatLabel(false).contains('Deira'), isTrue);
      expect(loc.formatLabel(true).contains('ديرة'), isTrue);
    });
  });
}
