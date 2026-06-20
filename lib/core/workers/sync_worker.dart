import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tripsfactory/core/utils/result.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/core/providers/connectivity_provider.dart';
import 'package:tripsfactory/core/services/offline_sync_service.dart';
import 'package:tripsfactory/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripsfactory/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripsfactory/core/utils/logger.dart';

/// Optional sleeper for tests (avoids real delays). Default null = use Future.delayed.
final sleeperForSyncWorkerProvider = Provider<Future<void> Function(Duration)?>(
  (ref) => null,
);

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  return SyncWorker(ref);
});

class SyncWorker {
  final Ref _ref;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  SyncWorker(this._ref) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _ref
        .read(connectivityProvider)
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
          final isOnline = results.any(
            (result) =>
                result == ConnectivityResult.wifi ||
                result == ConnectivityResult.mobile,
          );

          if (isOnline) {
            _syncPendingActions();
          }
        });

    // Cleanup on dispose (if used in a provider that can close)
    _ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });
  }

  Future<void> _syncPendingActions() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;

    try {
      final syncService = _ref.read(offlineSyncServiceProvider);
      final actions = syncService.getPendingActions();

      if (actions.isNotEmpty) {
        StructuredLogger.info(
          'SyncWorker',
          'Starting sync of ${actions.length} actions',
        );
      }

      for (final action in actions) {
        const int maxRetries = 4;
        bool success = false;
        bool permanentlyRejected = false;

        for (int attempt = 0; attempt < maxRetries; attempt++) {
          try {
            final dynamic result = await _executeAction(action);

            if (result is Result && !result.isSuccess) {
              throw Exception(
                result.errorOrNull?.userMessage ?? 'Action failed',
              );
            }

            success = true;
            StructuredLogger.info(
              'SyncWorker',
              'Action ${action.id} synced successfully',
            );
            break; // Break the retry loop if successful
          } catch (e, st) {
            // State changed while offline (FSM/guard rejection): retrying
            // will never succeed, so drop the action instead of poisoning
            // the queue forever.
            if (_isPermanentRejection(e)) {
              permanentlyRejected = true;
              StructuredLogger.warning(
                'SyncWorker',
                'Action ${action.id} permanently rejected (stale state): $e. '
                'Removing from queue.',
              );
              break;
            }
            StructuredLogger.error(
              'SyncWorker',
              'Attempt ${attempt + 1} failed for action ${action.id}',
              e,
              st,
            );
            if (attempt < maxRetries - 1) {
              final delay = Duration(
                seconds: 1 << attempt,
              ); // Exponential backoff: 1s, 2s, 4s
              final sleeper = _ref.read(sleeperForSyncWorkerProvider);
              await (sleeper ?? (Duration d) => Future.delayed(d))(delay);
            }
          }
        }

        if (success || permanentlyRejected) {
          await syncService.removeAction(action.id);
        } else {
          StructuredLogger.error(
            'SyncWorker',
            'Max retries reached for action ${action.id}. Skipping and continuing queue.',
          );
          // Continue processing other actions — this one stays in queue for next sync
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// True when the backend (or the local FSM) rejected the action for a
  /// reason that cannot resolve itself: an illegal status transition, a
  /// guard-trigger veto, or a locked terminal row. Network errors and
  /// transient failures return false and keep retrying.
  bool _isPermanentRejection(Object error) {
    final msg = error.toString();
    const permanentMarkers = [
      'ILLEGAL_TRANSITION',
      'INCOHERENT_STATE',
      'TIMESTAMP_IMMUTABLE',
      'TRIP_LOCKED',
      'FORBIDDEN:',
      'illegal_transition',
    ];
    return permanentMarkers.any(msg.contains);
  }

  Future<dynamic> _executeAction(dynamic action) async {
    switch (action.type) {
      case 'create_trip':
        return await _ref
            .read(tripRepositoryProvider)
            .createTrip(action.payload);
      case 'cancel_trip':
        final tripId = action.payload['tripId'] as String?;
        if (tripId == null) throw ArgumentError('tripId missing');
        return await _ref.read(tripRepositoryProvider).cancelTrip(tripId);
      case 'accept_booking':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .acceptBooking(bookingId);
      case 'reject_booking':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .rejectBooking(bookingId);
      case 'mark_goods_handed_over':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .markGoodsHandedOver(bookingId);
      case 'mark_payment_sent':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .markPaymentSent(bookingId);
      case 'confirm_goods_received_by_client':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .confirmGoodsReceivedByClient(bookingId);
      case 'confirm_goods_received':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .confirmGoodsReceived(bookingId);
      case 'confirm_payment_received':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .confirmPaymentReceived(bookingId);
      case 'mark_goods_delivered':
        final bookingId = action.payload['bookingId'] as String?;
        if (bookingId == null) throw ArgumentError('bookingId missing');
        return await _ref
            .read(bookingRepositoryProvider)
            .markGoodsDelivered(bookingId);
      case 'create_direct_booking':
        final userId = action.payload['userId'] as String?;
        final driverId = action.payload['driverId'] as String?;
        final tripId = action.payload['tripId'] as String?;
        if (userId == null || driverId == null || tripId == null) {
          throw ArgumentError('Required IDs are missing');
        }
        return await _ref
            .read(bookingRepositoryProvider)
            .createDirectBooking(
              userId: userId,
              driverId: driverId,
              tripId: tripId,
            );
      default:
        StructuredLogger.warning(
          'SyncWorker',
          'Unknown offline action type: ${action.type}. Removing from queue.',
        );
        return Result<void>.failure(
          TripsFactoryException.withKey(
            'transient',
            'Unknown offline action type: ${action.type}',
          ),
        );
    }
  }

  // Allow manual trigger
  Future<void> triggerSync() => _syncPendingActions();
}
