import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/core/utils/result.dart';
import 'package:tripsfactory/features/ratings/data/rating_service.dart';
import 'package:tripsfactory/features/ratings/domain/repositories/rating_repository.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

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
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
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
    } on TripsFactoryException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        TripsFactoryException.withKey('unknown_error', e.toString(), e),
      );
    }
  }
}
