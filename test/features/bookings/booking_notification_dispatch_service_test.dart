import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tripsfactory/core/services/notification_service.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/booking_notification_dispatch_service.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/booking_notification_enrichment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class ThrowingEnrichmentService extends BookingNotificationEnrichmentService {
  ThrowingEnrichmentService() : super(MockSupabaseClient());

  @override
  Future<Map<String, dynamic>> enrichNotificationDataForBooking(
    String bookingId,
    Map<String, dynamic> base, {
    Map<String, dynamic>? bookingData,
  }) async {
    throw Exception('enrichment failed');
  }
}

class StaticEnrichmentService extends BookingNotificationEnrichmentService {
  StaticEnrichmentService(this.payload) : super(MockSupabaseClient());

  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> enrichNotificationDataForBooking(
    String bookingId,
    Map<String, dynamic> base, {
    Map<String, dynamic>? bookingData,
  }) async {
    return payload;
  }
}

void main() {
  late MockNotificationService notificationService;
  late ProviderContainer container;
  late Ref ref;

  setUp(() {
    notificationService = MockNotificationService();
    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
    );
    ref = container.read(Provider((r) => r));
    when(
      () => notificationService.sendNotificationToUser(
        userId: any(named: 'userId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
        recipientRole: any(named: 'recipientRole'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  test('continues and sends base payload when enrichment throws (3.25)', () async {
    final service = BookingNotificationDispatchService(
      ref,
      ThrowingEnrichmentService(),
    );

    await service.notifyUser(
      bookingId: 'b1',
      userId: 'u2',
      title: 'Title',
      body: 'Body',
      recipientRole: 'sender',
      baseData: {'type': 'booking_accepted', 'booking_id': 'b1'},
    );

    final captured = verify(
      () => notificationService.sendNotificationToUser(
        userId: 'u2',
        title: 'Title',
        body: 'Body',
        data: captureAny(named: 'data'),
        recipientRole: 'sender',
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(captured['type'], 'booking_accepted');
    expect(captured['booking_id'], 'b1');
  });

  test('does not throw when dispatch call throws (non-blocking)', () async {
    final service = BookingNotificationDispatchService(
      ref,
      StaticEnrichmentService({'type': 'booking_accepted'}),
    );

    when(
      () => notificationService.sendNotificationToUser(
        userId: any(named: 'userId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
        recipientRole: any(named: 'recipientRole'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenThrow(Exception('notification write failed'));

    await expectLater(
      () => service.notifyUser(
        bookingId: 'b1',
        userId: 'u2',
        title: 'Title',
        body: 'Body',
        recipientRole: 'sender',
        baseData: {'type': 'booking_cancelled', 'booking_id': 'b1'},
      ),
      returnsNormally,
    );
  });
}
