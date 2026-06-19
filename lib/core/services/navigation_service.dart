import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/config/app_routes.dart';
import 'package:tripship/core/router/app_router.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/features/auth/data/auth_service.dart';

final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService(ref);
});

class NavigationService {
  final Ref _ref;
  // Static so it survives provider recreation and hot restart.
  // Matches the lifetime of the static NotificationService._navigationHandler.
  static bool _isSetup = false;

  NavigationService(this._ref);

  void setupNotificationNavigation() {
    if (_isSetup) {
      return;
    }
    _isSetup = true;

    NotificationService.setNavigationHandler((data) {
      final router = _ref.read(routerProvider);
      final type = data['type'] as String?;
      final bookingId = data['booking_id'] as String?;
      final shipmentId = data['shipment_id'] as String?;
      final tripId = data['trip_id'] as String?;
      final ticketId = data['ticket_id'] ?? data['ticketId'];
      final otherUserName = data['other_user_name'] ?? data['other_name'] ?? '';
      final otherUserId = data['other_user_id'] ?? '';

      // 1. Account Status Changes
      if (type == 'account_blocked' || type == 'account_unblocked') {
        _ref.invalidate(currentUserProfileProvider);
        return;
      }

      // Driver/company application verdict: refresh the cached profile so
      // the new traveler/company status is visible immediately, then show it.
      if (type == 'verification_result') {
        _ref.invalidate(currentUserProfileProvider);
        router.push(AppRoutes.profile);
        return;
      }

      if (type == 'support_reply') {
        router.push(
          AppRoutes.support,
          extra: {
            if (ticketId != null) 'focusTicketId': ticketId.toString(),
          },
        );
        return;
      }

      // 2. Chat - Message or general chat notification
      if (bookingId != null && (type == 'new_message' || type == 'chat')) {
        router.push(
          AppRoutes.chat,
          extra: {
            'bookingId': bookingId,
            'tripId': tripId,
            'driverId': data['traveler_id'] ?? data['driver_id'] ?? '',
            'otherUserName': otherUserName,
            'otherUserId': otherUserId,
          },
        );
        return;
      }

      // 3. Trip Details - specific routing for trip-related events
      if (tripId != null) {
        final path = Uri(
          path: AppRoutes.tripDetails,
          queryParameters: {'id': tripId},
        ).toString();
        router.push(path);
        return;
      }

      // 4. Offer Details - special case for traveler notifications
      final offerId = data['offer_id'] ?? data['offerId'];
      if (offerId != null) {
        final path = Uri(
          path: AppRoutes.offerDetails,
          queryParameters: {'id': offerId},
        ).toString();
        router.push(path);
        return;
      }

      // 5. Shipment Details - specific routing for shipment-related events
      if (shipmentId != null) {
        final path = Uri(
          path: AppRoutes.shipmentDetails,
          queryParameters: {'id': shipmentId},
        ).toString();
        router.push(path);
        return;
      }

      // 6. Fallback Chat
      if (bookingId != null) {
        router.push(
          AppRoutes.chat,
          extra: {
            'bookingId': bookingId,
            'tripId': tripId,
            'otherUserName': otherUserName,
            'otherUserId': otherUserId,
          },
        );
      }
    });
  }
}
