import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/config/brand_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripship/features/auth/data/auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optional: Add logic here if we ever switch to pure data messages.
  // Currently, the Edge Function sends a `notification` payload, so FCM
  // automatically displays the background notification on Android/iOS.
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(Supabase.instance.client);
  // Eagerly initialize FCM on the canonical Riverpod instance.
  // initialize() is idempotent (static _isInitialized guard) so the bootstrap
  // call and this call are both safe to call concurrently.
  Future.microtask(service.initialize);
  return service;
});

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return Stream.value(0);
  return ref.watch(notificationServiceProvider).getNotifications(user.id).map((
    list,
  ) {
    return list.where((n) => n['is_read'] == false).length;
  });
});

bool isNotificationRead(Map<String, dynamic> notification) {
  return notification['is_read'] == true;
}

class NotificationService {
  final SupabaseClient _client;
  // Lazy so a subclass (e.g. demo mode) that overrides the FCM-using methods
  // can be constructed without a Firebase app initialized.
  late final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._client);

  // Static guard: ensures FCM setup runs only once across all instances
  // (app_bootstrap instance + Riverpod notificationServiceProvider instance).
  static bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    // Request permission (FCM)
    await _firebaseMessaging.requestPermission();

    // Android 13+ permission request (Local Notifications / System Tray)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      // Ask once to exempt the app from battery optimization. On aggressive
      // OEMs (Samsung/Xiaomi/etc.) the OS force-stops un-exempted apps when
      // swiped from Recents, and Android then withholds FCM until reopen —
      // this is why pushes stop after "closing" the app. Whitelisting keeps
      // background/closed delivery reliable (same mechanism big chat apps use).
      await _maybeRequestBatteryOptimizationExemption();
    }

    // Init local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            _handleNotificationTap(RemoteMessage(data: data));
          } catch (e, st) {
            StructuredLogger.error(
              'NotificationService',
              'Error parsing local notification payload',
              e,
              st,
            );
          }
        }
      },
    );

    // Create Android Notification Channel (Required for heads-up/background behavior)
    if (defaultTargetPlatform == TargetPlatform.android) {
      // New channel id: Android channels are immutable once created, so the
      // custom sound requires a fresh id (was tripship_high_importance_channel).
      const channel = AndroidNotificationChannel(
        BrandConfig.notificationChannelId,
        BrandConfig.notificationChannelName,
        description: 'Crucial notifications for trips, shipments, and offers',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          BrandConfig.notificationSoundAndroid,
        ),
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    // Initial token
    await updateToken();

    // Token refresh
    _firebaseMessaging.onTokenRefresh.listen(_storeToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Background/Terminated state tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // iOS Foreground settings
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initial message if app was opened from terminated state via notification
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Requests battery-optimization exemption once (Android). Opens the system
  /// "allow background activity" dialog. Gated by a one-time flag so the user
  /// is never nagged; if they already granted it, nothing happens.
  Future<void> _maybeRequestBatteryOptimizationExemption() async {
    try {
      if (await Permission.ignoreBatteryOptimizations.isGranted) return;
      final prefs = await SharedPreferences.getInstance();
      const askedKey = 'asked_battery_optimization_v1';
      if (prefs.getBool(askedKey) == true) return;
      await prefs.setBool(askedKey, true);
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e, st) {
      StructuredLogger.error(
        'NotificationService',
        'Battery optimization exemption request failed',
        e,
        st,
      );
    }
  }

  Future<void> updateToken() async {
    final token = await _firebaseMessaging.getToken();
    await _storeToken(token);
  }

  // Monotonically incrementing counter — avoids the 1-second collision window
  // that DateTime.now().millisecondsSinceEpoch ~/ 1000 would produce.
  int _notificationIdCounter = 0;
  int _nextNotificationId() => ++_notificationIdCounter;

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    StructuredLogger.info(
      'NotificationService',
      'Foreground message received: ${message.notification?.title}',
    );

    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? BrandConfig.brandName,
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      BrandConfig.notificationChannelId,
      BrandConfig.notificationChannelName,
      channelDescription:
          'Crucial notifications for trips, shipments, and offers',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        BrandConfig.notificationSoundAndroid,
      ),
      enableVibration: true,
      enableLights: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: BrandConfig.notificationSoundIos,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: _nextNotificationId(),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // ─── Navigation Handler (static by design) ──────────────────────────────
  //
  // These fields MUST be static: NotificationService is recreated by the
  // Riverpod provider on hot restart, but the navigation callback and any
  // queued tap data must survive the provider lifecycle. Use
  // clearNavigationState() in tests to prevent state leak between test cases.
  static Map<String, dynamic>? _pendingMessageData;
  static void Function(Map<String, dynamic> data)? _navigationHandler;

  void _handleNotificationTap(RemoteMessage message) {
    if (_navigationHandler != null) {
      _navigationHandler!.call(message.data);
    } else {
      StructuredLogger.info(
        'NotificationService',
        'Navigation handler not yet registered, queueing tap.',
      );
      _pendingMessageData = message.data;
    }
  }

  static void setNavigationHandler(
    void Function(Map<String, dynamic> data)? handler,
  ) {
    _navigationHandler = handler;
    if (_navigationHandler != null && _pendingMessageData != null) {
      StructuredLogger.info(
        'NotificationService',
        'Firing queued notification tap.',
      );
      _navigationHandler!.call(_pendingMessageData!);
      _pendingMessageData = null;
    }
  }

  /// Resets static navigation state. Call this in tests to prevent state leaks.
  @visibleForTesting
  static void clearNavigationState() {
    _pendingMessageData = null;
    _navigationHandler = null;
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? recipientRole,
    String? idempotencyKey,
  }) async {
    // Never notify the currently logged-in user for their own actions:
    // they are already on-screen and see the result immediately.
    // This prevents cluttering their notification feed with self-actions.
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId != null && currentUserId == userId) {
      return;
    }

    try {
      final finalData = Map<String, dynamic>.from(data ?? {});
      if (recipientRole != null) finalData['recipient_role'] = recipientRole;

      // Server-side insert: send_user_notification validates that the
      // caller has an active relationship with the recipient (direct
      // notifications-table inserts for other users are blocked by RLS).
      await _client.rpc(
        'send_user_notification',
        params: {
          'p_recipient_id': userId,
          'p_title': title,
          'p_body': body,
          'p_data': finalData,
          'p_idempotency_key': ?idempotencyKey,
        },
      );
    } catch (e, stack) {
      StructuredLogger.error(
        'NotificationService',
        'Failed to persist notification',
        e,
        stack,
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> _storeToken(String? token) async {
    if (token == null) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.rpc(
        'upsert_notification_token',
        params: {'p_token': token, 'p_platform': defaultTargetPlatform.name},
      );
    } catch (e, stack) {
      StructuredLogger.error(
        'NotificationService',
        'Failed to save notification token',
        e,
        stack,
      );
    }
  }
}
