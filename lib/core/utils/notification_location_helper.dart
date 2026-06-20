import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/models/location_model.dart';

class NotificationLocationHelper {
  /// Adds origin_name and destination_name to notification data from a trip.
  static Future<void> addOriginDestinationToData(
    SupabaseClient supabase,
    Map<String, dynamic> data,
    String? tripId,
  ) async {
    if (tripId != null) {
      final t = await supabase
          .from('trips')
          .select(
            'origin_loc:locations!origin_location_id(city_name_ar, city_name_en, province_name_ar, province_name_en), dest_loc:locations!dest_location_id(city_name_ar, city_name_en, province_name_ar, province_name_en)',
          )
          .eq('id', tripId)
          .maybeSingle();
      if (t != null) {
        var orig = t['origin_loc'];
        var dest = t['dest_loc'];
        if (orig is List && orig.isNotEmpty) orig = orig.first;
        if (dest is List && dest.isNotEmpty) dest = dest.first;
        if (orig is Map) {
          data['origin_name_ar'] = Location.formatLocationName(
            orig['province_name_ar'],
            orig['city_name_ar'],
          );
          data['origin_name_en'] = Location.formatLocationName(
            orig['province_name_en'],
            orig['city_name_en'],
          );
        }
        if (dest is Map) {
          data['destination_name_ar'] = Location.formatLocationName(
            dest['province_name_ar'],
            dest['city_name_ar'],
          );
          data['destination_name_en'] = Location.formatLocationName(
            dest['province_name_en'],
            dest['city_name_en'],
          );
        }
      }
    }
  }
}
