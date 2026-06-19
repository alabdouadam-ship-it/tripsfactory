import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/utils/logger.dart';

class AdService {
  final SupabaseClient _client;

  AdService(this._client);

  Future<List<Map<String, dynamic>>> getActiveAds() async {
    try {
      final response = await _client
          .from('ads')
          .select()
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(1);
      return List<Map<String, dynamic>>.from(response);
    } on SocketException {
      StructuredLogger.warning('AdService', 'Ads: unavailable (no network)');
      return [];
    } catch (e, st) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('hostname') ||
          msg.contains('Failed host lookup')) {
        StructuredLogger.warning('AdService', 'Ads: unavailable (network)');
      } else {
        StructuredLogger.error('AdService', 'Error fetching ads', e, st);
      }
      return [];
    }
  }
}

final adServiceProvider = Provider(
  (ref) => AdService(Supabase.instance.client),
);

final activeAdsProvider = FutureProvider((ref) {
  return ref.watch(adServiceProvider).getActiveAds();
});
