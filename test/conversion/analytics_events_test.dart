import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/fake_analytics.dart';

/// Stage 5 funnel event contract. When the app adds analytics injection,
/// wire it to FakeAnalytics in tests and assert these events on key actions.
void main() {
  group('Funnel analytics contract', () {
    late FakeAnalytics analytics;

    setUp(() {
      analytics = FakeAnalytics();
    });

    test('track records event name and params', () {
      analytics.track('booking_viewed', {
        'bookingId': 'b1',
        'tripId': 't1',
        'shipmentId': 's1',
        'role': 'driver',
        'state': 'accepted',
      });
      expect(analytics.events.length, 1);
      expect(analytics.events.first.name, 'booking_viewed');
      expect(analytics.events.first.params!['bookingId'], 'b1');
      expect(analytics.events.first.params!['tripId'], 't1');
    });

    test('exactly one event per action when each called once', () {
      analytics.track('booking_viewed', {'bookingId': 'b1'});
      analytics.track('offer_accepted_clicked', {'bookingId': 'b1'});
      analytics.track('payment_started', {'bookingId': 'b1'});
      analytics.track('payment_succeeded', {'bookingId': 'b1'});
      analytics.track('handover_confirmed', {'bookingId': 'b1'});
      analytics.track('delivery_confirmed', {'bookingId': 'b1'});
      analytics.track('review_started', {'bookingId': 'b1'});
      analytics.track('review_submitted', {'bookingId': 'b1'});

      expect(analytics.countNamed('booking_viewed'), 1);
      expect(analytics.countNamed('offer_accepted_clicked'), 1);
      expect(analytics.countNamed('payment_started'), 1);
      expect(analytics.countNamed('payment_succeeded'), 1);
      expect(analytics.countNamed('handover_confirmed'), 1);
      expect(analytics.countNamed('delivery_confirmed'), 1);
      expect(analytics.countNamed('review_started'), 1);
      expect(analytics.countNamed('review_submitted'), 1);
    });

    test('events include critical ids', () {
      analytics.track('booking_viewed', {
        'bookingId': 'b1',
        'tripId': 't1',
        'shipmentId': 's1',
        'role': 'driver',
        'state': 'pending',
      });
      final params = analytics.events.first.params!;
      expect(params.containsKey('bookingId'), true);
      expect(params.containsKey('tripId'), true);
      expect(params.containsKey('state'), true);
    });

    test('duplicate track calls result in duplicate entries (app must avoid rebuild duplicates)', () {
      analytics.track('booking_viewed', {'bookingId': 'b1'});
      analytics.track('booking_viewed', {'bookingId': 'b1'});
      expect(analytics.countNamed('booking_viewed'), 2);
    });

    test('clear resets events', () {
      analytics.track('booking_viewed', {});
      analytics.clear();
      expect(analytics.events.length, 0);
    });
  });
}
