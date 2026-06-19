import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/utils/result.dart';
import 'package:tripship/features/ratings/data/rating_service.dart';
import 'package:tripship/features/ratings/domain/repositories/rating_repository.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';

final ratingRepositoryProvider = Provider<IRatingRepository>((ref) {
  final service = ref.watch(ratingServiceProvider);
  return RatingRepository(service);
});

class RatingRepository implements IRatingRepository {
  final RatingService _service;

  RatingRepository(this._service);

  @override
  Future<Result<Set<String>>> getRatedBookingIds(
    List<String> bookingIds,
  ) async {
    try {
      final ids = await _service.getRatedBookingIds(bookingIds);
      return Result.success(ids);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }

  @override
  Future<Result<void>> submitRating({
    required String bookingId,
    required double rating,
    required String raterId,
    required String ratedId,
    required String roleRated,
    String? comment,
  }) async {
    try {
      await _service.submitRating(
        bookingId: bookingId,
        rating: rating.toInt(),
        raterId: raterId,
        ratedId: ratedId,
        roleRated: roleRated,
        comment: comment,
      );
      return Result.success(null);
    } on TripShipException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripShipException.withKey('unknown_error', e.toString(), e),
      );
    }
  }
}
