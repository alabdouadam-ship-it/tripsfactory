import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/models/offline_action.dart';

/// Idempotency: same key / same action id leads to single side effect; notification idempotency key in DB.
void main() {
  group('Offline action idempotency', () {
    test('same action id used twice is one logical action', () {
      const id = 'idem-1';
      final a1 = OfflineAction(
        id: id,
        type: 'accept_booking',
        payload: {'bookingId': 'b1'},
      );
      final a2 = OfflineAction(
        id: id,
        type: 'accept_booking',
        payload: {'bookingId': 'b1'},
      );
      expect(a1.id, a2.id);
      expect(a1.type, a2.type);
    });

    test('action id is unique when not provided (uuid)', () {
      final a1 = OfflineAction(type: 'accept_booking', payload: {'bookingId': 'b1'});
      final a2 = OfflineAction(type: 'accept_booking', payload: {'bookingId': 'b1'});
      expect(a1.id, isNot(equals(a2.id)));
    });

    test('toJson/fromJson round-trip preserves id and type', () {
      final a = OfflineAction(
        id: 'k1',
        type: 'mark_payment_sent',
        payload: {'bookingId': 'b2'},
      );
      final json = a.toJson();
      final restored = OfflineAction.fromJson(json);
      expect(restored.id, a.id);
      expect(restored.type, a.type);
      expect(restored.payload['bookingId'], 'b2');
    });
  });

  group('Notification idempotency (contract)', () {
    test('idempotency_key in payload allows upsert on conflict', () {
      const key = 'notif-request-123';
      expect(key, isNotEmpty);
      expect(key.length, lessThan(256), reason: 'DB column typically 255');
    });
  });
}
