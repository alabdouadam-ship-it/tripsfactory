import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripsfactory/core/models/offline_action.dart';
import 'package:tripsfactory/core/utils/logger.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  throw UnimplementedError('Initialized in main.dart');
});

class OfflineSyncService {
  final SharedPreferences _prefs;
  static const String _queueKey = 'offline_actions_queue';

  OfflineSyncService(this._prefs);

  List<OfflineAction> getPendingActions() {
    final String? queueString = _prefs.getString(_queueKey);
    if (queueString == null || queueString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(queueString);
      return decodedList
          .map((item) => OfflineAction.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e, st) {
      StructuredLogger.error(
        'OfflineSyncService',
        'Corrupt offline queue — clearing to prevent permanent block',
        e,
        st,
      );
      // Clear the corrupt data so it doesn't permanently block future syncs
      _prefs.remove(_queueKey);
      return [];
    }
  }

  Future<void> enqueueAction(OfflineAction action) async {
    final actions = getPendingActions();
    actions.add(action);
    await _saveActions(actions);
  }

  Future<void> removeAction(String actionId) async {
    final actions = getPendingActions();
    actions.removeWhere((a) => a.id == actionId);
    await _saveActions(actions);
  }

  Future<void> _saveActions(List<OfflineAction> actions) async {
    final String encodedList = jsonEncode(
      actions.map((a) => a.toJson()).toList(),
    );
    await _prefs.setString(_queueKey, encodedList);
  }
}
