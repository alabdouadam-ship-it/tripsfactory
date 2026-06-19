import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/features/bookings/data/lifecycle/booking_notification_enrichment_service.dart';

void main() {
  group('applyNotificationEnrichmentShape', () {
    test('adds trip and traveler identifiers', () {
      final result = applyNotificationEnrichmentShape(
        {'type': 'booking_accepted', 'booking_id': 'b1'},
        tripId: 't1',
        travelerId: 'u2',
      );

      expect(result['trip_id'], 't1');
      expect(result['traveler_id'], 'u2');
      expect(result['other_user_id'], 'u2');
    });

    test('adds traveler display name when available', () {
      final result = applyNotificationEnrichmentShape(
        {'type': 'booking_accepted'},
        travelerName: 'Ali Ahmad',
      );

      expect(result['other_user_name'], 'Ali Ahmad');
    });

    test('keeps base payload untouched when enrichment values missing', () {
      final base = {'type': 'booking_rejected', 'booking_id': 'b2'};
      final result = applyNotificationEnrichmentShape(base);

      expect(result, base);
      expect(result.containsKey('trip_id'), isFalse);
      expect(result.containsKey('traveler_id'), isFalse);
      expect(result.containsKey('other_user_name'), isFalse);
    });
  });
}
