import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/core/utils/logger.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return CacheService(prefs);
});

class CacheService {
  final PreferencesService _prefs;

  CacheService(this._prefs);

  static const _cacheDuration = Duration(hours: 1);

  bool _isStale(DateTime? at) {
    if (at == null) return true;
    return DateTime.now().difference(at) > _cacheDuration;
  }

  Future<void> cacheTrips(List<Trip> list, String cacheKey) async {
    try {
      final jsonList = list.map((t) => t.toJson()).toList();
      await _prefs.setString(cacheKey, jsonEncode(jsonList));
      await _prefs.setString(
        '${cacheKey}_at',
        DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      StructuredLogger.error('CacheService', 'failed to cache trips', e, st);
    }
  }

  Future<List<Trip>?> getCachedTrips(String cacheKey) async {
    try {
      final atStr = _prefs.getStringSync('${cacheKey}_at');
      final at = atStr != null ? DateTime.tryParse(atStr) : null;
      if (_isStale(at)) return null;

      final raw = _prefs.getStringSync(cacheKey);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      StructuredLogger.error(
        'CacheService',
        'failed to read cached trips',
        e,
        st,
      );
      return null;
    }
  }

  /// Clears cached trips for the given cache key. Call on user-initiated refresh.
  Future<void> clearTrips(String cacheKey) async {
    await _prefs.remove(cacheKey);
    await _prefs.remove('${cacheKey}_at');
  }
}
