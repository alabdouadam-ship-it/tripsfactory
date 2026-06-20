import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/features/trips/data/route_alert_model.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

final routeAlertServiceProvider = Provider<RouteAlertService>((ref) {
  return RouteAlertService(Supabase.instance.client);
});

class RouteAlertService {
  final SupabaseClient _client;

  RouteAlertService(this._client);

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

    await _client.from('route_alerts').insert(payload);
  }

  /// Fetches user's alerts and resolves location names from locations table.
  /// Uses RPC get_my_route_alerts when available (bypasses RLS issues); else direct select.
  /// [locale] is used to pick Arabic vs English names (e.g. 'ar' or 'en').
  Future<List<RouteAlert>> getMyAlerts(
    String userId, {
    String locale = 'ar',
  }) async {
    List<dynamic> rawList;
    try {
      final rpcResponse = await _client.rpc('get_my_route_alerts');
      rawList = rpcResponse as List;
      StructuredLogger.info(
        'RouteAlertService',
        'RPC returned ${rawList.length} alerts',
      );
    } catch (rpcError, rpcSt) {
      StructuredLogger.error(
        'RouteAlertService',
        'RPC failed, falling back to direct query',
        rpcError,
        rpcSt,
      );
      try {
        final response = await _client
            .from('route_alerts')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        rawList = response as List;
      } catch (directError, directSt) {
        StructuredLogger.error(
          'RouteAlertService',
          'Direct query also failed',
          directError,
          directSt,
        );
        throw TripsFactoryException.withKey(
          'failed_load_route_alerts',
          'Failed to load route alerts for user.',
          directError,
        );
      }
    }

    final alerts = rawList.map((e) => RouteAlert.fromJson(e)).toList();

    final locIds = <String>{};
    for (final a in alerts) {
      if (a.originLocationId != null) locIds.add(a.originLocationId!);
      if (a.destLocationId != null) locIds.add(a.destLocationId!);
    }
    if (locIds.isEmpty) return alerts;

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
      return RouteAlert(
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
    await _client.from('route_alerts').delete().eq('id', alertId);
  }

  /// Returns user IDs whose route alerts match the given trip.
  /// Match: is_internal, and (origin_location_id if set), (dest_location_id if set).
  /// For alerts with origin_city/dest_city/province, checks trip locations.
  Future<List<String>> getMatchingAlertUserIds({
    required String tripId,
    required String originLocationId,
    required String destLocationId,
    required bool isInternal,
    required String excludeUserId,
  }) async {
    try {
      final alerts = await _client
          .from('route_alerts')
          .select(
            'user_id, origin_location_id, dest_location_id, origin_province, dest_province, origin_city, dest_city, is_internal',
          )
          .eq('is_internal', isInternal)
          .neq('user_id', excludeUserId);

      final list = alerts as List;
      Map<String, dynamic>? originLoc;
      Map<String, dynamic>? destLoc;

      final needLocations = list.any(
        (a) =>
            a['origin_province'] != null ||
            a['dest_province'] != null ||
            a['origin_city'] != null ||
            a['dest_city'] != null,
      );

      if (needLocations) {
        final locs = await _client
            .from('locations')
            .select(
              'id, city_name_ar, city_name_en, province_name_ar, province_name_en',
            )
            .inFilter('id', [originLocationId, destLocationId]);
        for (final loc in locs as List) {
          if (loc['id'] == originLocationId) originLoc = loc;
          if (loc['id'] == destLocationId) destLoc = loc;
        }
      }

      final userIds = <String>{};
      for (final a in list) {
        bool originMatch =
            a['origin_location_id'] == null ||
            a['origin_location_id'] == originLocationId;
        if (!originMatch &&
            (a['origin_province'] != null || a['origin_city'] != null) &&
            originLoc != null) {
          originMatch = _locationMatchesAlert(
            originLoc,
            a['origin_province'],
            a['origin_city'],
          );
        }
        bool destMatch =
            a['dest_location_id'] == null ||
            a['dest_location_id'] == destLocationId;
        if (!destMatch &&
            (a['dest_province'] != null || a['dest_city'] != null) &&
            destLoc != null) {
          destMatch = _locationMatchesAlert(
            destLoc,
            a['dest_province'],
            a['dest_city'],
          );
        }
        if (originMatch && destMatch) userIds.add(a['user_id'].toString());
      }
      return userIds.toList();
    } catch (_) {
      return [];
    }
  }

  static bool _locationMatchesAlert(
    Map<String, dynamic> loc,
    dynamic province,
    dynamic city,
  ) {
    if (province != null && province.toString().isNotEmpty) {
      final p = province.toString().trim().toLowerCase();
      if (p !=
              (loc['province_name_ar'] ?? '').toString().trim().toLowerCase() &&
          p !=
              (loc['province_name_en'] ?? '').toString().trim().toLowerCase()) {
        return false;
      }
    }
    if (city != null && city.toString().isNotEmpty) {
      final c = city.toString().trim().toLowerCase();
      if (!(loc['city_name_ar'] ?? '').toString().toLowerCase().contains(c) &&
          !(loc['city_name_en'] ?? '').toString().toLowerCase().contains(c)) {
        return false;
      }
    }
    return true;
  }
}
