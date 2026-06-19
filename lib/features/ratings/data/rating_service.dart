import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';

final ratingServiceProvider = Provider<RatingService>((ref) {
  return RatingService(Supabase.instance.client);
});

class RatingService {
  final SupabaseClient _client;

  RatingService(this._client);

  String getRaterId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw TripShipException('User not authenticated');
    }
    return id;
  }

  // Submit a Rating (score 1-5, optional comment)
  Future<void> submitRating({
    required String raterId,
    required String ratedId,
    required String roleRated, // 'driver' or 'client'
    required int rating,
    String? comment,
    String? bookingId,
    String? offerId,
  }) async {
    // Input validation first — before any DB reads
    if (rating < 1 || rating > 5) {
      throw TripShipException('Rating must be between 1 and 5');
    }
    if (raterId == ratedId) {
      throw TripShipException('Cannot rate yourself');
    }

    // Guard: prevent duplicate ratings
    if (bookingId != null) {
      final alreadyRated = await hasRatedForBooking(bookingId);
      if (alreadyRated) return;
    }
    if (offerId != null) {
      final alreadyRated = await hasRatedForOffer(offerId);
      if (alreadyRated) return;
    }

    final trimmedComment = comment?.trim();
    final safeComment = (trimmedComment == null || trimmedComment.isEmpty)
        ? null
        : trimmedComment.length > 500
        ? trimmedComment.substring(0, 500)
        : trimmedComment;

    try {
      await _client.from('ratings').insert({
        'rater_id': raterId,
        'rated_id': ratedId,
        'role_rated': roleRated,
        'rating': rating,
        'comment': safeComment,
        'booking_id': bookingId,
        'offer_id': offerId,
      });
      StructuredLogger.info(
        'RatingService',
        'Rating submitted successfully for user $ratedId',
      );
    } catch (e, st) {
      StructuredLogger.error('RatingService', 'Failed to submit rating', e, st);
      // Rethrow to preserve original Supabase error code (e.g. unique constraint)
      rethrow;
    }
  }

  /// Check if the current user has rated the other party for this booking
  Future<bool> hasRatedForBooking(String bookingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await _client
        .from('ratings')
        .select('id')
        .eq('booking_id', bookingId)
        .eq('rater_id', userId)
        .limit(1)
        .maybeSingle();
    return res != null;
  }

  /// Get set of booking IDs that the current user has already rated
  Future<Set<String>> getRatedBookingIds(List<String> bookingIds) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || bookingIds.isEmpty) return {};
    final res = await _client
        .from('ratings')
        .select('booking_id')
        .inFilter('booking_id', bookingIds)
        .eq('rater_id', userId);
    return (res as List)
        .map((r) => r['booking_id'] as String)
        .whereType<String>()
        .toSet();
  }

  /// Check if the current user has rated the other party for this offer
  Future<bool> hasRatedForOffer(String offerId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await _client
        .from('ratings')
        .select('id')
        .eq('offer_id', offerId)
        .eq('rater_id', userId)
        .limit(1)
        .maybeSingle();
    return res != null;
  }

  /// Get set of offer IDs that the current user has already rated
  Future<Set<String>> getRatedOfferIds(List<String> offerIds) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || offerIds.isEmpty) return {};
    final res = await _client
        .from('ratings')
        .select('offer_id')
        .inFilter('offer_id', offerIds)
        .eq('rater_id', userId);
    return (res as List)
        .map((r) => r['offer_id'] as String)
        .whereType<String>()
        .toSet();
  }

  // Get Profile Ratings Stats (Aggregates are already in profile table, but this fetches list if needed)
  Future<List<Map<String, dynamic>>> getReviews(
    String userId,
    String role,
  ) async {
    final response = await _client
        .from('ratings')
        .select('*, rater:profiles!rater_id(full_name, avatar_url)')
        .eq('rated_id', userId)
        .eq('role_rated', role)
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }
}
