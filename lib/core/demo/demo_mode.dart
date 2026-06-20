import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/demo/demo_booking_repository.dart';
import 'package:tripship/core/demo/demo_data.dart';
import 'package:tripship/core/demo/demo_notification_service.dart';
import 'package:tripship/core/demo/demo_trip_repository.dart';
import 'package:tripship/core/services/ad_service.dart';
import 'package:tripship/core/services/app_config_service.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripship/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripship/features/trips/data/trip_service.dart';

/// Installs a fake, offline auth session so `auth.currentUser` is non-null
/// across the app (preventing null-session crashes), without any network call.
/// The crafted session has a far-future expiry, so `recoverSession` accepts it
/// and does not attempt a token refresh.
Future<void> initDemoSession() async {
  try {
    await Supabase.instance.client.auth.recoverSession(
      jsonEncode(DemoData.sessionJson()),
    );
  } catch (e) {
    StructuredLogger.warning('DemoMode', 'recoverSession failed: $e');
  }
}

/// Riverpod overrides that swap real (network-backed) data sources for seeded
/// in-memory ones. This keeps demo mode fully offline — no failed network or
/// realtime traffic for the screens the demo surfaces.
List<Override> demoProviderOverrides() {
  return [
    // Treat the user as signed in for the router, using the recovered session.
    authStateProvider.overrideWith(
      (ref) => Stream.value(
        AuthState(
          AuthChangeEvent.signedIn,
          Supabase.instance.client.auth.currentSession,
        ),
      ),
    ),
    // Seeded profile, locations and trips.
    currentUserProfileProvider.overrideWith((ref) async => DemoData.currentUser),
    locationsProvider.overrideWith((ref) async => DemoData.locations),
    tripRepositoryProvider.overrideWithValue(DemoTripRepository()),
    bookingRepositoryProvider.overrideWithValue(DemoBookingRepository()),
    // Quiet, offline notifications (no FCM, no realtime).
    notificationServiceProvider.overrideWith(
      (ref) => DemoNotificationService(),
    ),
    // Avoid backend queries for config/ads.
    appConfigProvider.overrideWith((ref) async => AppConfig(updateRequired: false)),
    activeAdsProvider.overrideWith(
      (ref) async => const <Map<String, dynamic>>[],
    ),
  ];
}
