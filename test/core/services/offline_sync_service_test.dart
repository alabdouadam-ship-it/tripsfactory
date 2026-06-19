import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/services/offline_sync_service.dart';
import 'package:tripship/core/models/offline_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineSyncService Tests', () {
    test('enqueues an action successfully', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = OfflineSyncService(prefs);

      final action = OfflineAction(
        type: 'create_trip',
        payload: {'key': 'value'},
      );
      await service.enqueueAction(action);

      final pending = service.getPendingActions();
      expect(pending.length, equals(1));
      expect(pending.first.type, equals('create_trip'));
      expect(pending.first.payload['key'], equals('value'));
    });

    test('removes an action successfully', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = OfflineSyncService(prefs);

      final action = OfflineAction(type: 'create_trip', payload: {});
      await service.enqueueAction(action);

      var pending = service.getPendingActions();
      expect(pending.length, equals(1));

      await service.removeAction(pending.first.id);

      pending = service.getPendingActions();
      expect(pending.isEmpty, isTrue);
    });

    test('maintains order of enqueued actions', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = OfflineSyncService(prefs);

      await service.enqueueAction(OfflineAction(type: 'first', payload: {}));
      await service.enqueueAction(OfflineAction(type: 'second', payload: {}));

      final pending = service.getPendingActions();
      expect(pending.length, equals(2));
      expect(pending[0].type, equals('first'));
      expect(pending[1].type, equals('second'));
    });
  });
}
