import 'package:tripsfactory/core/utils/result.dart';

abstract class IRatingRepository {
  Future<Result<Set<String>>> getRatedBookingIds(List<String> bookingIds);
  Future<Result<void>> submitRating({
    required String bookingId,
    required double rating,
    required String raterId,
    required String ratedId,
    required String roleRated,
    String? comment,
  });
}
