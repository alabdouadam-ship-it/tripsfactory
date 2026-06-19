import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_cancellation_guard.dart';
import 'booking_handshake_coordinator.dart';
import 'booking_notification_dispatch_service.dart';
import 'booking_notification_enrichment_service.dart';
import 'booking_photo_upload_service.dart';
import 'trip_status_sync_service.dart';

/// Shared dependencies for booking lifecycle commands.
class BookingLifecycleContext {
  BookingLifecycleContext(this.ref)
      : supabase = Supabase.instance.client,
        handshake = BookingHandshakeCoordinator(Supabase.instance.client),
        tripSync = TripStatusSyncService(Supabase.instance.client),
        enrichment = BookingNotificationEnrichmentService(Supabase.instance.client),
        photos = BookingPhotoUploadService(Supabase.instance.client),
        cancelGuard = const BookingCancellationGuard() {
    notifications = BookingNotificationDispatchService(ref, enrichment);
  }

  final Ref ref;
  final SupabaseClient supabase;
  final BookingHandshakeCoordinator handshake;
  final TripStatusSyncService tripSync;
  final BookingNotificationEnrichmentService enrichment;
  final BookingPhotoUploadService photos;
  final BookingCancellationGuard cancelGuard;
  late final BookingNotificationDispatchService notifications;
}
