import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/core/services/notification_service.dart';

/// Demo [NotificationService] that performs no Firebase/network work and
/// returns no notifications. Used in demo mode so the app has no push/FCM
/// dependency and produces no realtime traffic.
class DemoNotificationService extends NotificationService {
  DemoNotificationService() : super(Supabase.instance.client);

  @override
  Future<void> initialize() async {
    // No-op: no FCM/local-notification setup in demo mode.
  }

  @override
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return Stream.value(const <Map<String, dynamic>>[]);
  }

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}
}
