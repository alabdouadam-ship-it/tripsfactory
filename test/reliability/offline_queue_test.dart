import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripsfactory/core/services/offline_sync_service.dart';
import 'package:tripsfactory/core/models/offline_action.dart';

/// Offline queue: persist, order by createdAt, remove only on success, partial success leaves rest queued.
void main() {
  late OfflineSyncService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = OfflineSyncService(prefs);
  });

  test('enqueue and getPendingActions returns in createdAt order', () async {
    await service.enqueueAction(OfflineAction(
      id: 'a1',
      type: 'accept_booking',
      payload: {'bookingId': 'b1'},
      createdAt: DateTime.utc(2025, 1, 1, 10, 0),
    ));
    await service.enqueueAction(OfflineAction(
      id: 'a2',
      type: 'reject_booking',
      payload: {'bookingId': 'b2'},
      createdAt: DateTime.utc(2025, 1, 1, 9, 0),
    ));

    final pending = service.getPendingActions();
    expect(pending.length, 2);
    expect(pending[0].id, 'a2', reason: 'Earlier createdAt first');
    expect(pending[1].id, 'a1');
  });

  test('removeAction removes by id and persists', () async {
    await service.enqueueAction(OfflineAction(
      id: 'x1',
      type: 'accept_booking',
      payload: {'bookingId': 'b1'},
    ));
    await service.removeAction('x1');
    expect(service.getPendingActions(), isEmpty);
  });

  test('queue persists across new service instance (same prefs)', () async {
    await service.enqueueAction(OfflineAction(
      id: 'p1',
      type: 'mark_goods_handed_over',
      payload: {'bookingId': 'b1'},
    ));
    final prefs = await SharedPreferences.getInstance();
    final service2 = OfflineSyncService(prefs);
    final pending = service2.getPendingActions();
    expect(pending.length, 1);
    expect(pending[0].id, 'p1');
    expect(pending[0].type, 'mark_goods_handed_over');
  });

  test('multiple enqueues then remove first leaves rest', () async {
    await service.enqueueAction(OfflineAction(
      id: 'first',
      type: 'accept_booking',
      payload: {'bookingId': 'b1'},
      createdAt: DateTime.utc(2025, 1, 1, 8, 0),
    ));
    await service.enqueueAction(OfflineAction(
      id: 'second',
      type: 'accept_booking',
      payload: {'bookingId': 'b2'},
      createdAt: DateTime.utc(2025, 1, 1, 9, 0),
    ));
    await service.removeAction('first');
    final pending = service.getPendingActions();
    expect(pending.length, 1);
    expect(pending[0].id, 'second');
  });
}
