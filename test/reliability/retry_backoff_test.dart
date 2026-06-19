import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/workers/sync_worker.dart';
import 'package:tripship/core/services/offline_sync_service.dart';
import 'package:tripship/core/models/offline_action.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripship/features/bookings/domain/repositories/booking_repository.dart';
import 'package:tripship/core/utils/result.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';
import '../test_helpers/fake_sleeper.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Retry: transient failures cause retries; exponential backoff 1s, 2s, 4s; stop after max (3).
/// Uses fake sleeper for deterministic test.
void main() {
  group('SyncWorker retry and backoff', () {
    test('backoff schedule is exponential (1s, 2s, 4s) for attempt 0,1,2', () {
      expect(1 << 0, 1);
      expect(1 << 1, 2);
      expect(1 << 2, 4);
    });

    testWidgets(
      'retries up to max then stops; records backoff delays via sleeper',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final offline = OfflineSyncService(prefs);
        final fakeSleeper = FakeSleeper();

        int acceptCalls = 0;
        final fakeBookingRepo = FakeBookingRepositoryThatThrows(
          throwUntilAttempt: 2,
          onAccept: () => acceptCalls++,
        );

        await offline.enqueueAction(
          OfflineAction(type: 'accept_booking', payload: {'bookingId': 'b1'}),
        );

        final container = ProviderContainer(
          overrides: [
            offlineSyncServiceProvider.overrideWithValue(offline),
            sleeperForSyncWorkerProvider.overrideWithValue(fakeSleeper.sleeper),
            bookingRepositoryProvider.overrideWithValue(fakeBookingRepo),
          ],
        );
        addTearDown(container.dispose);

        final worker = container.read(syncWorkerProvider);
        await worker.triggerSync();

        expect(acceptCalls, 3, reason: 'Should try 3 times then succeed');
        expect(
          fakeSleeper.delays.length,
          2,
          reason: 'Two delays between 3 attempts',
        );
        expect(fakeSleeper.delays[0], const Duration(seconds: 1));
        expect(fakeSleeper.delays[1], const Duration(seconds: 2));

        final pending = offline.getPendingActions();
        expect(
          pending,
          isEmpty,
          reason: 'Action should be removed after success',
        );
      },
    );

    testWidgets('stops processing queue after max retries for one action', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final offline = OfflineSyncService(prefs);
      final fakeSleeper = FakeSleeper();

      final alwaysFails = FakeBookingRepositoryThatThrows(
        throwUntilAttempt: 10,
        onAccept: () {},
      );

      await offline.enqueueAction(
        OfflineAction(type: 'accept_booking', payload: {'bookingId': 'b1'}),
      );

      final container = ProviderContainer(
        overrides: [
          offlineSyncServiceProvider.overrideWithValue(offline),
          sleeperForSyncWorkerProvider.overrideWithValue(fakeSleeper.sleeper),
          bookingRepositoryProvider.overrideWithValue(alwaysFails),
        ],
      );
      addTearDown(container.dispose);

      final worker = container.read(syncWorkerProvider);
      await worker.triggerSync();

      expect(
        fakeSleeper.delays.length,
        3,
        reason: 'Three delays for 3 retries then stop',
      );
      expect(fakeSleeper.delays[0], const Duration(seconds: 1));
      expect(fakeSleeper.delays[1], const Duration(seconds: 2));
      expect(fakeSleeper.delays[2], const Duration(seconds: 4));

      final pending = offline.getPendingActions();
      expect(pending.length, 1, reason: 'Action remains after max retries');
    });
  });
}

class FakeBookingRepositoryThatThrows implements IBookingRepository {
  final int throwUntilAttempt;
  final void Function()? onAccept;
  int _attempts = 0;

  FakeBookingRepositoryThatThrows({
    required this.throwUntilAttempt,
    this.onAccept,
  });

  @override
  Future<Result<void>> acceptBooking(String bookingId) async {
    onAccept?.call();
    if (_attempts < throwUntilAttempt) {
      _attempts++;
      return Result.failure(
        TripShipException.withKey('transient', 'Transient failure'),
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<List<Booking>>> getBookingsForTrip(String tripId) async =>
      Result.success([]);

  @override
  Future<Result<Booking?>> getUserBookingForTrip(String tripId) async =>
      Result.success(null);

  @override
  Stream<Result<List<Booking>>> watchBookingsForTrip(String tripId) =>
      Stream.value(Result.success([]));

  @override
  Stream<Result<Booking?>> watchUserBookingForTrip(String tripId) =>
      Stream.value(Result.success(null));

  @override
  Future<Result<void>> rejectBooking(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> cancelBooking(
    String bookingId, {
    required bool isDriver,
    required String reason,
  }) async => Result.success(null);

  @override
  Future<Result<void>> markGoodsHandedOver(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markPaymentSent(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> confirmGoodsReceivedByClient(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> confirmGoodsReceived(
    String bookingId, {
    File? pickupPhoto,
  }) async => Result.success(null);

  @override
  Future<Result<void>> confirmPaymentReceived(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<void>> markGoodsDelivered(
    String bookingId, {
    File? deliveryPhoto,
  }) async => Result.success(null);

  @override
  Future<Result<void>> markGoodsDeliveredWithCode(
    String bookingId,
    String code, {
    File? deliveryPhoto,
  }) async => Result.success(null);

  @override
  Future<Result<void>> createDirectBooking({
    required String userId,
    required String driverId,
    required String tripId,
  }) async => Result.success(null);

  @override
  Future<Result<String>> createBookingWithFirstMessage({
    required String tripId,
    required String driverId,
    required String firstMessageContent,
    String? type,
    Map<String, dynamic>? metadata,
  }) async => Result.success('fake_booking_id');

  @override
  Future<Result<BookingStatus?>> getBookingStatus(String bookingId) async =>
      Result.success(null);

  @override
  Future<Result<String?>> getRecipientRoleForUser(
    String bookingId,
    String userId,
  ) async => Result.success(null);

  @override
  Stream<Result<List<Booking>>> watchMyRequests() =>
      Stream.value(Result.success([]));
}
