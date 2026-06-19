import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';

void main() {
  group('Booking.fromJson', () {
    test('parses minimal valid json', () {
      final json = _minimalBookingJson();
      final b = Booking.fromJson(json);
      expect(b.id, 'b1');
      expect(b.driverId, 'd1');
      expect(b.offerPrice, 50.0);
      expect(b.status, BookingStatus.pending);
    });

    test('parses all booking statuses', () {
      final statuses = <String, BookingStatus>{
        'pending': BookingStatus.pending,
        'accepted': BookingStatus.accepted,
        'rejected': BookingStatus.rejected,
        'completed': BookingStatus.completed,
        'cancelled': BookingStatus.cancelled,
        'in_transit': BookingStatus.inTransit,
        'delivered': BookingStatus.delivered,
        'in_communication': BookingStatus.inCommunication,
      };
      for (final entry in statuses.entries) {
        final b = Booking.fromJson(_minimalBookingJson(status: entry.key));
        expect(b.status, entry.value, reason: 'status ${entry.key}');
      }
    });

    test('parses lifecycle timestamps', () {
      final json = _minimalBookingJson()
        ..addAll({
          'goods_handed_by_sender_at': '2025-01-02T10:00:00Z',
          'goods_received_by_driver_at': '2025-01-02T11:00:00Z',
          'payment_marked_by_sender_at': '2025-01-03T10:00:00Z',
          'payment_confirmed_by_driver_at': '2025-01-03T11:00:00Z',
          'goods_delivered_by_driver_at': '2025-01-04T10:00:00Z',
          'goods_received_by_client_at': '2025-01-04T11:00:00Z',
        });
      final b = Booking.fromJson(json);
      expect(b.goodsHandedBySenderAt, isNotNull);
      expect(b.goodsReceivedByDriverAt, isNotNull);
      expect(b.paymentMarkedBySenderAt, isNotNull);
      expect(b.paymentConfirmedByDriverAt, isNotNull);
      expect(b.goodsDeliveredByDriverAt, isNotNull);
      expect(b.goodsReceivedByClientAt, isNotNull);
    });

    test('parses timeline', () {
      final json = _minimalBookingJson()
        ..['timeline'] = [
          {'event': 'offer_accepted', 'timestamp': '2025-01-01T12:00:00Z'},
        ];
      final b = Booking.fromJson(json);
      expect(b.timeline.length, 1);
      expect(b.timeline.first['event'], 'offer_accepted');
    });
  });

  group('Booking computed properties', () {
    test('isCollected when goods_received_by_driver_at is set', () {
      final b = Booking.fromJson(_minimalBookingJson()
        ..['goods_received_by_driver_at'] = '2025-01-02T10:00:00Z');
      expect(b.isCollected, isTrue);
    });

    test('isCollected when goods_received_by_driver_at is null', () {
      final b = Booking.fromJson(_minimalBookingJson());
      expect(b.isCollected, isFalse);
    });

    test('isPaid when payment_confirmed_by_driver_at is set', () {
      final b = Booking.fromJson(_minimalBookingJson()
        ..['payment_confirmed_by_driver_at'] = '2025-01-02T10:00:00Z');
      expect(b.isPaid, isTrue);
    });

    test('isPaid when payment_confirmed_by_driver_at is null', () {
      final b = Booking.fromJson(_minimalBookingJson());
      expect(b.isPaid, isFalse);
    });

    test('isDelivered when goods_received_by_client_at is set', () {
      final b = Booking.fromJson(_minimalBookingJson()
        ..['goods_received_by_client_at'] = '2025-01-02T10:00:00Z');
      expect(b.isDelivered, isTrue);
    });

    test('isDelivered when goods_received_by_client_at is null', () {
      final b = Booking.fromJson(_minimalBookingJson());
      expect(b.isDelivered, isFalse);
    });

    test('isWaitingForDriverPickupConfirm', () {
      final handedOnly = Booking.fromJson(_minimalBookingJson()
        ..['goods_handed_by_sender_at'] = '2025-01-02T10:00:00Z');
      expect(handedOnly.isWaitingForDriverPickupConfirm, isTrue);

      final both = Booking.fromJson(_minimalBookingJson()
        ..['goods_handed_by_sender_at'] = '2025-01-02T10:00:00Z'
        ..['goods_received_by_driver_at'] = '2025-01-02T11:00:00Z');
      expect(both.isWaitingForDriverPickupConfirm, isFalse);
    });
  });

  group('Booking.toJson', () {
    test('round-trip preserves core fields', () {
      final json = _minimalBookingJson(status: 'accepted');
      final b = Booking.fromJson(json);
      final out = b.toJson();
      expect(out['id'], 'b1');
      expect(out['status'], 'accepted');
      expect(out['offer_price'], 50.0);
    });
  });
}

Map<String, dynamic> _minimalBookingJson({String status = 'pending'}) => {
      'id': 'b1',
      'traveler_id': 'd1',
      'trip_id': null,
      'requester_id': null,
      'offer_price': 50.0,
      'status': status,
      'created_at': '2025-01-01T00:00:00Z',
    };
