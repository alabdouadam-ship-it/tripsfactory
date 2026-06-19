import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/utils/logger.dart';

final safetyServiceProvider = Provider((ref) => SafetyService());

enum ReportResult { reportedOnly, reportedAndBlocked }

class SafetyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Report a user
  Future<ReportResult> reportUser({
    required String reportedId,
    required String reason,
    String? comment,
    String? targetType,
    String? targetShipmentId,
    String? targetRatingId,
    String? targetTripId,
  }) async {
    final myId = _supabase.auth.currentUser!.id;
    if (myId == reportedId) {
      return ReportResult.reportedOnly; // Prevent self-reporting
    }

    final payload = <String, dynamic>{
      'reporter_id': myId,
      'reported_id': reportedId,
      'reason': reason,
      'comment': comment,
    };
    if (targetType != null) payload['target_type'] = targetType;
    if (targetShipmentId != null) {
      payload['target_shipment_id'] = targetShipmentId;
    }
    if (targetRatingId != null) payload['target_rating_id'] = targetRatingId;
    if (targetTripId != null) payload['target_trip_id'] = targetTripId;

    await _supabase.from('reports').insert(payload);

    final hasActiveEngagement = await _supabase.rpc(
      'has_active_engagement',
      params: {'p_user_a': myId, 'p_user_b': reportedId},
    );

    if (hasActiveEngagement == true) {
      return ReportResult.reportedOnly;
    }

    try {
      await _supabase.from('blocks').insert({
        'blocker_id': myId,
        'blocked_id': reportedId,
      });
      StructuredLogger.info(
        'SafetyService',
        'User $reportedId reported and automatically blocked',
      );
      return ReportResult.reportedAndBlocked;
    } catch (e) {
      // Catch duplicate block inserts or RLS errors
      StructuredLogger.warning(
        'SafetyService',
        'Failed to block reported user $reportedId, returning reportedOnly',
        null,
      );
      return ReportResult.reportedOnly;
    }
  }

  // Block a user
  Future<void> blockUser(String blockedId) async {
    final myId = _supabase.auth.currentUser!.id;
    if (myId == blockedId) {
      return; // Prevent self-blocking
    }

    // Prevent blocking if there's an active trip or shipment
    final hasActiveEngagement = await _supabase.rpc(
      'has_active_engagement',
      params: {'p_user_a': myId, 'p_user_b': blockedId},
    );

    if (hasActiveEngagement == true) {
      throw TripShipException.withKey(
        'active_engagement_exists',
        'Cannot block user during an active trip or shipment.',
      );
    }
    try {
      await _supabase.from('blocks').insert({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
      StructuredLogger.info('SafetyService', 'User $blockedId fully blocked');
    } catch (e, st) {
      StructuredLogger.error(
        'SafetyService',
        'Failed to block user $blockedId',
        e,
        st,
      );
      throw TripShipException('block_failed');
    }
  }

  // Unblock a user
  Future<void> unblockUser(String blockedId) async {
    final myId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('blocks').delete().match({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });
      StructuredLogger.info('SafetyService', 'User $blockedId unblocked');
    } catch (e, st) {
      StructuredLogger.error(
        'SafetyService',
        'Failed to unblock user $blockedId',
        e,
        st,
      );
      throw TripShipException('unblock_failed');
    }
  }

  // Check if I have blocked a user
  Future<bool> isBlocked(String userId) async {
    final myId = _supabase.auth.currentUser!.id;
    final count = await _supabase.from('blocks').count(CountOption.exact).match(
      {'blocker_id': myId, 'blocked_id': userId},
    );
    return count > 0;
  }

  // Check if either user has blocked the other
  Future<bool> isUserBlocked(String userId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return false;

    try {
      // Check if I blocked them
      final myBlockCount = await _supabase
          .from('blocks')
          .count(CountOption.exact)
          .match({'blocker_id': myId, 'blocked_id': userId});

      if (myBlockCount > 0) return true;

      // Check if they blocked me
      final theirBlockCount = await _supabase
          .from('blocks')
          .count(CountOption.exact)
          .match({'blocker_id': userId, 'blocked_id': myId});

      return theirBlockCount > 0;
    } catch (_) {
      return false; // Fail open if error
    }
  }

  // Watch if I have blocked another user in real time
  Stream<bool> watchHasBlocked(String otherUserId) {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value(false);

    return _supabase
        .from('blocks')
        .stream(primaryKey: ['blocker_id', 'blocked_id'])
        .eq('blocker_id', myId)
        .map((events) => events.any((row) => row['blocked_id'] == otherUserId));
  }

  // Watch if I am blocked by another user in real time
  Stream<bool> watchIsBlockedBy(String otherUserId) {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value(false);

    return _supabase
        .from('blocks')
        .stream(primaryKey: ['blocker_id', 'blocked_id'])
        .eq('blocker_id', otherUserId)
        .map((events) => events.any((row) => row['blocked_id'] == myId));
  }

  // Get list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final myId = _supabase.auth.currentUser!.id;

    // Fetch blocks with profile details
    // We assume 'profiles' is related to 'blocks' via 'blocked_id'
    // If foreign key constraint exists:
    final response = await _supabase
        .from('blocks')
        .select('blocked_id, profiles!blocked_id(id, full_name, avatar_url)')
        .eq('blocker_id', myId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get list of user IDs blocked by a specific user
  Future<List<String>> getBlockedUserIds(String blockerId) async {
    final response = await _supabase
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', blockerId);

    return (response as List).map((e) => e['blocked_id'].toString()).toList();
  }
}
