import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/features/shipments/data/shipment_alert_model.dart';
import 'package:tripship/core/utils/logger.dart';

final shipmentAlertServiceProvider = Provider<ShipmentAlertService>((ref) {
  return ShipmentAlertService(Supabase.instance.client);
});

class ShipmentAlertService {
  final SupabaseClient _client;

  ShipmentAlertService(this._client);

  Future<void> createAlert({
    required String userId,
    String? originLocationId,
    String? destLocationId,
    String? originProvince,
    String? destProvince,
    String? originCity,
    String? destCity,
    required bool isInternal,
  }) async {
    final hasOrigin =
        originLocationId != null ||
        (originProvince != null && originProvince.isNotEmpty) ||
        (originCity != null && originCity.isNotEmpty);
    final hasDest =
        destLocationId != null ||
        (destProvince != null && destProvince.isNotEmpty) ||
        (destCity != null && destCity.isNotEmpty);
    if (!hasOrigin || !hasDest) {
      throw ArgumentError('Origin and destination must both be specified');
    }

    final payload = {
      'user_id': userId,
      'origin_location_id': originLocationId,
      'dest_location_id': destLocationId,
      'origin_province': originProvince,
      'dest_province': destProvince,
      'origin_city': originCity,
      'dest_city': destCity,
      'is_internal': isInternal,
    };

    await _client.from('shipment_alerts').insert(payload);
  }

  Future<List<ShipmentAlert>> getMyAlerts(
    String userId, {
    String locale = 'ar',
  }) async {
    List<dynamic> rawList;
    try {
      final response = await _client
          .from('shipment_alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      rawList = response as List;
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentAlertService',
        'getMyAlerts failed',
        e,
        st,
      );
      rawList = [];
    }

    final alerts = rawList.map((e) => ShipmentAlert.fromJson(e)).toList();

    final locIds = <String>{};
    for (final a in alerts) {
      if (a.originLocationId != null) locIds.add(a.originLocationId!);
      if (a.destLocationId != null) locIds.add(a.destLocationId!);
    }
    if (locIds.isEmpty) {
      return alerts;
    }

    final locs = await _client
        .from('locations')
        .select(
          'id, city_name_ar, city_name_en, province_name_ar, province_name_en',
        )
        .inFilter('id', locIds.toList());

    final locMap = <String, Map<String, dynamic>>{};
    for (final loc in locs as List) {
      locMap[loc['id'].toString()] = loc;
    }

    final useAr = locale.startsWith('ar');
    return alerts.map((a) {
      String? originName;
      String? destName;
      if (a.originLocationId != null) {
        final loc = locMap[a.originLocationId];
        if (loc != null) {
          originName = useAr
              ? (loc['city_name_ar'] ?? loc['province_name_ar'])?.toString()
              : (loc['city_name_en'] ?? loc['province_name_en'])?.toString();
        }
      }
      if (a.destLocationId != null) {
        final loc = locMap[a.destLocationId];
        if (loc != null) {
          destName = useAr
              ? (loc['city_name_ar'] ?? loc['province_name_ar'])?.toString()
              : (loc['city_name_en'] ?? loc['province_name_en'])?.toString();
        }
      }
      return ShipmentAlert(
        id: a.id,
        userId: a.userId,
        originLocationId: a.originLocationId,
        destLocationId: a.destLocationId,
        originProvince: a.originProvince,
        destProvince: a.destProvince,
        originCity: a.originCity,
        destCity: a.destCity,
        isInternal: a.isInternal,
        createdAt: a.createdAt,
        originDisplayName: originName,
        destDisplayName: destName,
      );
    }).toList();
  }

  Future<void> deleteAlert(String alertId) async {
    await _client.from('shipment_alerts').delete().eq('id', alertId);
  }

  Future<List<String>> getMatchingAlertUserIds({
    required String shipmentId,
    required String originLocationId,
    required String destLocationId,
    required bool isInternal,
    required String excludeUserId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_matching_alerts_rpc',
        params: {
          'p_shipment_id': shipmentId,
          'p_origin_loc_id': originLocationId,
          'p_dest_loc_id': destLocationId,
          'p_is_internal': isInternal,
          'p_sender_id': excludeUserId,
        },
      );

      final list = response as List;
      return list.map((row) => row['matched_user_id'].toString()).toList();
    } catch (e, st) {
      StructuredLogger.error(
        'ShipmentAlertService',
        'getMatchingAlertUserIds rpc failed',
        e,
        st,
      );
      return [];
    }
  }
}
