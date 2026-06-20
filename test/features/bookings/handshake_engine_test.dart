import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/handshake_engine.dart';

void main() {
  const engine = HandshakeEngine();
  const bookingId = 'b1';
  const now = '2026-01-01T00:00:00.000Z';
  const userId = 'u1';

  group('HandshakeEngine', () {
    test('skips when timestamp field already set', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'goods_handed_by_sender',
        nowIso: now,
        authUserId: userId,
        booking: {
          'status': 'accepted',
          'timeline': <dynamic>[],
          'goods_handed_by_sender_at': 'old',
        },
        fieldName: 'goods_handed_by_sender_at',
        newStatus: null,
      );
      expect(result, isA<HandshakeSkip>());
      expect((result as HandshakeSkip).reason,
          HandshakeSkipReason.timestampAlreadySet);
    });

    test('skips terminal booking (completed)', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'noop',
        nowIso: now,
        authUserId: userId,
        booking: {
          'status': 'completed',
          'timeline': <dynamic>[],
        },
        fieldName: null,
        newStatus: null,
      );
      expect(result, isA<HandshakeSkip>());
      expect((result as HandshakeSkip).reason,
          HandshakeSkipReason.terminalBooking);
    });

    test('skips when newStatus equals current', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'noop',
        nowIso: now,
        authUserId: userId,
        booking: {
          'status': 'accepted',
          'timeline': <dynamic>[],
        },
        fieldName: null,
        newStatus: BookingStatus.accepted,
      );
      expect(result, isA<HandshakeSkip>());
      expect((result as HandshakeSkip).reason,
          HandshakeSkipReason.statusAlreadyMatches);
    });

    test('throws illegal_transition for invalid FSM move', () {
      expect(
        () => engine.evaluate(
          bookingId: bookingId,
          timelineEvent: 'bad',
          nowIso: now,
          authUserId: userId,
          booking: {
            'status': 'pending',
            'timeline': <dynamic>[],
          },
          fieldName: null,
          newStatus: BookingStatus.delivered,
        ),
        throwsA(
          predicate<TripsFactoryException>(
            (e) => e.messageKey == 'illegal_transition',
          ),
        ),
      );
    });

    test('applies handshake with timeline + status + optional field', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'booking_accepted',
        nowIso: now,
        authUserId: userId,
        booking: {
          'status': 'pending',
          'timeline': <dynamic>[
            {'event': 'created', 'timestamp': 't0', 'user_id': 'x'},
          ],
        },
        fieldName: null,
        newStatus: BookingStatus.accepted,
      );
      expect(result, isA<HandshakeApply>());
      final upd = (result as HandshakeApply).updates;
      expect(upd['status'], 'accepted');
      final tl = upd['timeline'] as List;
      expect(tl.length, 2);
      expect(tl.last['event'], 'booking_accepted');
      expect(tl.last['timestamp'], now);
      expect(tl.last['user_id'], userId);
      expect(tl.last.keys.toSet(), containsAll(['event', 'timestamp', 'user_id']));
    });

    test(
        'timeline append uses authUserId event timestamp and keys (3.24 3.28)',
        () {
      const actorId = 'actor-xyz';
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'payment_marked',
        nowIso: now,
        authUserId: actorId,
        booking: {
          'status': 'accepted',
          'timeline': <dynamic>[],
        },
        fieldName: 'payment_marked_by_sender_at',
        newStatus: null,
      );
      expect(result, isA<HandshakeApply>());
      final tl =
          ((result as HandshakeApply).updates['timeline'] as List).last
              as Map<String, dynamic>;
      expect(tl['event'], 'payment_marked');
      expect(tl['timestamp'], now);
      expect(tl['user_id'], actorId);
    });

    test('skips terminal booking (cancelled)', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'noop',
        nowIso: now,
        authUserId: userId,
        booking: {
          'status': 'cancelled',
          'timeline': <dynamic>[],
        },
        fieldName: null,
        newStatus: null,
      );
      expect(result, isA<HandshakeSkip>());
      expect((result as HandshakeSkip).reason,
          HandshakeSkipReason.terminalBooking);
    });

    test('merges additionalUpdates', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'cancel',
        nowIso: now,
        authUserId: userId,
        booking: {
          'status': 'pending',
          'timeline': <dynamic>[],
        },
        fieldName: null,
        newStatus: BookingStatus.cancelled,
        additionalUpdates: {'message': 'Reason: x'},
      );
      expect(result, isA<HandshakeApply>());
      final upd = (result as HandshakeApply).updates;
      expect(upd['message'], 'Reason: x');
      expect(upd['status'], 'cancelled');
    });

    test('when status column is null, still applies without FSM checks', () {
      final result = engine.evaluate(
        bookingId: bookingId,
        timelineEvent: 'edge',
        nowIso: now,
        authUserId: userId,
        booking: {
          'timeline': <dynamic>[],
        },
        fieldName: null,
        newStatus: BookingStatus.accepted,
      );
      expect(result, isA<HandshakeApply>());
    });
  });
}
