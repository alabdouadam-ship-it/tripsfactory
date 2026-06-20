import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/core/widgets/delivery_code_card.dart';
import 'package:tripsfactory/features/bookings/data/booking_model.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/features/ratings/presentation/rating_dialog.dart';
import 'package:tripsfactory/features/bookings/presentation/widgets/booking_progress_stepper.dart';
import 'package:tripsfactory/features/chat/data/chat_service.dart';
import '../controllers/trip_details_controller.dart';

class TripSenderSection extends ConsumerWidget {
  final String tripId;
  final Booking? userBooking;
  final bool isLoading;
  final bool hasActiveBooking;
  final Set<String> ratedBookingIds;
  final Trip trip;
  final AppLocalizations localizations;

  const TripSenderSection({
    super.key,
    required this.tripId,
    required this.userBooking,
    required this.isLoading,
    required this.hasActiveBooking,
    required this.ratedBookingIds,
    required this.trip,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tripDetailsControllerProvider(tripId).notifier);

    return Column(
      children: [
        if (userBooking != null) ...[
          _buildBookingStatusCard(context, controller),
          const SizedBox(height: 12),
        ],
        if (trip.status != TripStatus.completed &&
            trip.status != TripStatus.full &&
            trip.status != TripStatus.cancelled &&
            userBooking?.status != BookingStatus.cancelled &&
            !hasActiveBooking)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : controller.contactTraveler,
              icon: const Icon(Icons.handshake),
              label: Text(localizations.bookNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final unreadAsync = userBooking == null
                ? const AsyncValue.data(0)
                : ref.watch(unreadChatCountProvider(userBooking!.id));
            final unreadCount = unreadAsync.value ?? 0;

            return SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => _startChat(context, userBooking),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(
                    color: unreadCount > 0 ? Colors.blue : Colors.grey,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text('$unreadCount'),
                      child: Icon(
                        Icons.message,
                        color: unreadCount > 0 ? Colors.blue : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      localizations.messages,
                      style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: unreadCount > 0 ? Colors.blue : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingStatusCard(
    BuildContext context,
    TripDetailsController controller,
  ) {
    final status = userBooking!.status;
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getStatusIcon(status), color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(status, localizations),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (userBooking!.status == BookingStatus.pending ||
                  (userBooking!.status == BookingStatus.accepted &&
                      userBooking!.goodsReceivedByDriverAt == null))
                Positioned(
                  right: Localizations.localeOf(context).languageCode == 'ar'
                      ? null
                      : -16,
                  left: Localizations.localeOf(context).languageCode == 'ar'
                      ? -16
                      : null,
                  top: -12,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[700]),
                    onSelected: (value) {
                      if (value == 'cancel') {
                        _showCancelBookingDialog(context, controller);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.cancelBookingTitle,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (status != BookingStatus.pending &&
              status != BookingStatus.cancelled &&
              status != BookingStatus.rejected) ...[
            const SizedBox(height: 12),
            BookingProgressStepper(booking: userBooking!),
          ],
          const SizedBox(height: 12),
          _buildHandshakeActions(context, controller),
          // ─── Delivery OTP Code (shown to sender) ───
          // The code comes from the sender-only delivery_codes table.
          if (userBooking!.goodsReceivedByClientAt == null &&
              (userBooking!.status == BookingStatus.accepted ||
                  userBooking!.status == BookingStatus.inTransit ||
                  userBooking!.status == BookingStatus.delivered))
            DeliveryCodeCard(
              bookingId: userBooking!.id,
              title: localizations.deliveryCodeLabel,
              hint: localizations.deliveryCodeInstruction,
              copiedLabel: localizations.deliveryCodeLabel,
              padding: const EdgeInsets.only(top: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildHandshakeActions(
    BuildContext context,
    TripDetailsController controller,
  ) {
    List<Widget> actions = [];

    // ─── Goods Handover (sender marks goods handed when accepted) ───
    if (userBooking!.status == BookingStatus.accepted &&
        userBooking!.goodsHandedBySenderAt == null) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => controller.markHandover(userBooking!.id),
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(localizations.handshakeHandedGoods),
        ),
      );
    }

    // ─── Goods Received by Traveler indicator ───
    if (userBooking!.status == BookingStatus.accepted &&
        userBooking!.goodsHandedBySenderAt != null &&
        userBooking!.goodsReceivedByDriverAt == null) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            localizations.handshakeWaitingDriver,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      );
    } else if (userBooking!.goodsReceivedByDriverAt != null &&
        userBooking!.status == BookingStatus.inTransit) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                localizations.goodsReceivedByTravelerIndicator,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Payment (shown when in_transit or goods received) ───
    if (userBooking!.status != BookingStatus.completed &&
        (userBooking!.status == BookingStatus.inTransit ||
            userBooking!.goodsReceivedByDriverAt != null)) {
      if (userBooking!.paymentConfirmedByDriverAt == null &&
          userBooking!.paymentMarkedBySenderAt == null) {
        actions.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.markPayment(userBooking!.id),
              icon: const Icon(Icons.lock_outline),
              label: Text(localizations.actionRequiredPaymentSender),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
      } else if (userBooking!.paymentMarkedBySenderAt != null &&
          userBooking!.paymentConfirmedByDriverAt == null) {
        actions.add(
          Text(
            localizations.handshakeWaitingDriver,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        );
      } else if (userBooking!.paymentConfirmedByDriverAt != null) {
        // ─── Payment Confirmed indicator ───
        actions.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  '✅ ${localizations.paymentConfirmedIndicator}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // ─── Confirm Receipt at Destination (client confirms delivery) ───
    if ((userBooking!.status == BookingStatus.delivered ||
            userBooking!.status == BookingStatus.inTransit) &&
        userBooking!.goodsReceivedByClientAt == null) {
      actions.add(
        ElevatedButton(
          onPressed: () => controller.confirmReceipt(userBooking!.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: Text(localizations.handshakeGoodsReceived),
        ),
      );
    }

    // ─── Completed: Rate ───
    if (userBooking!.status == BookingStatus.completed) {
      if (!ratedBookingIds.contains(userBooking!.id)) {
        actions.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _rateDriver(context, controller),
              icon: const Icon(Icons.star, size: 24),
              label: Text(
                localizations.rateYourExperience,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        );
      } else {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '✅ ${localizations.thankYouForRating}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions,
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.green;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.inTransit:
        return Colors.blue;
      case BookingStatus.delivered:
        return Colors.teal;
      case BookingStatus.completed:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.inTransit:
        return Icons.local_shipping;
      case BookingStatus.delivered:
        return Icons.done_all;
      case BookingStatus.completed:
        return Icons.verified;
      case BookingStatus.cancelled:
        return Icons.cancel_presentation;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(BookingStatus status, AppLocalizations loc) {
    switch (status) {
      case BookingStatus.pending:
        return loc.statusPending;
      case BookingStatus.accepted:
        return loc.statusAccepted;
      case BookingStatus.rejected:
        return loc.statusRejected;
      case BookingStatus.inTransit:
        return loc.statusPickedUp;
      case BookingStatus.delivered:
        return loc.statusDelivered;
      case BookingStatus.completed:
        return loc.statusCompleted;
      case BookingStatus.inCommunication:
        return loc.statusInCommunication;
      case BookingStatus.cancelled:
        return loc.statusCancelled;
    }
  }

  void _startChat(BuildContext context, Booking? booking) {
    context.push(
      '/chat',
      extra: {
        'bookingId': booking?.id,
        'tripId': trip.id,
        'driverId': trip.driverId,
        'otherUserName': trip.driver?.fullName ?? localizations.unknownTraveler,
        'otherUserId': trip.driverId,
      },
    );
  }

  void _rateDriver(
    BuildContext context,
    TripDetailsController controller,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratedUserId: trip.driverId,
        ratedUserRole: 'driver',
        bookingId: userBooking!.id,
      ),
    );
    if (result == true) {
      controller.addRatedBookingId(userBooking!.id);
      controller.loadUserBooking();
    }
  }

  void _showCancelBookingDialog(
    BuildContext context,
    TripDetailsController controller,
  ) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.cancelBookingTitle,
          style: TextStyle(color: Colors.red[800]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.cancelBookingConfirmMessage),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: localizations.cancelBookingReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.confirmCancellation),
          ),
        ],
      ),
    );
    if (confirm == true) {
      controller.cancelBooking(
        userBooking!.id,
        isDriver: false,
        reason: reasonController.text.trim().isEmpty
            ? 'No reason provided'
            : reasonController.text.trim(),
      );
    }
    reasonController.dispose();
  }
}
