import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/chat/data/chat_model.dart';
import 'package:tripship/features/chat/data/chat_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/l10n_context.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/ratings/presentation/rating_dialog.dart';
import 'package:tripship/features/bookings/presentation/widgets/booking_progress_stepper.dart';
import 'package:tripship/features/shipments/presentation/widgets/shipment_otp_dialog.dart';
import '../controllers/trip_details_controller.dart';
import 'package:tripship/core/theme/tripship_motion_tokens.dart';

class TripBookingsList extends ConsumerWidget {
  final String tripId;
  final List<Booking> bookings;
  final Set<String> ratedBookingIds;
  final AppLocalizations localizations;

  const TripBookingsList({
    super.key,
    required this.tripId,
    required this.bookings,
    required this.ratedBookingIds,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          localizations.noBookingsYet,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: bookings.map((booking) {
        final requesterName =
            booking.requester?.fullName ?? localizations.unknown;

        final description = booking.status == BookingStatus.inCommunication
            ? localizations.statusInCommunication
            : localizations.directBooking;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _startChat(context, ref, booking, requesterName),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, booking, requesterName, description),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1),
                  ),
                  if (booking.status != BookingStatus.pending &&
                      booking.status != BookingStatus.cancelled &&
                      booking.status != BookingStatus.rejected) ...[
                    BookingProgressStepper(booking: booking),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Divider(height: 1),
                    ),
                  ],
                  _buildMessage(booking, localizations),
                  _buildFooter(context, ref, booking),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Booking booking,
    String name,
    String desc,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final userId = booking.requester?.id ?? booking.senderId;
            if (userId != null) {
              context.push(
                '/traveler-profile',
                extra: {
                  'driverId': userId,
                  'driverName': name,
                  'role': 'client',
                },
              );
            }
          },
          child: CircleAvatar(
            radius: 24,
            backgroundImage:
                booking.requester?.avatarUrl != null &&
                    booking.requester!.avatarUrl!.trim().isNotEmpty
                ? CachedNetworkImageProvider(booking.requester!.avatarUrl!)
                : null,
            child:
                booking.requester?.avatarUrl == null ||
                    booking.requester!.avatarUrl!.trim().isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (booking.requester?.identityDocUrl != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.green, size: 16),
                    const SizedBox(width: 2),
                    const Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              if (booking.status != BookingStatus.inCommunication)
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
            ],
          ),
        ),
        _buildStatusBadge(context, booking.status),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessage(Booking booking, AppLocalizations localizations) {
    if (booking.message == null ||
        booking.message!.isEmpty ||
        booking.message == 'Direct Inquiry' ||
        booking.message == localizations.directBooking ||
        booking.message == localizations.statusInCommunication) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${localizations.messageLabel}: "${booking.message}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, Booking booking) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildMessages(ref, booking),
        const SizedBox(width: 8),
        Expanded(
          child: _BookingActionButtons(
            booking: booking,
            tripId: tripId,
            ratedBookingIds: ratedBookingIds,
          ),
        ),
      ],
    );
  }

  Widget _buildMessages(WidgetRef ref, Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.unreadMessages,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        StreamBuilder<List<ChatMessage>>(
          stream: ref.read(chatServiceProvider).getMessages(booking.id),
          builder: (context, snapshot) {
            final count =
                snapshot.data?.where((m) => !m.isMe && !m.isRead).length ?? 0;
            return Row(
              children: [
                const Icon(Icons.mail_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return localizations.statusPending;
      case BookingStatus.accepted:
        return localizations.statusAccepted;
      case BookingStatus.inTransit:
        return localizations.statusPickedUp;
      case BookingStatus.delivered:
        return localizations.statusDelivered;
      case BookingStatus.completed:
        return localizations.statusCompleted;
      case BookingStatus.cancelled:
        return localizations.statusCancelled;
      case BookingStatus.inCommunication:
        return localizations.statusInCommunication;
      default:
        return status.name;
    }
  }

  void _startChat(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    String name,
  ) {
    final otherUserId = booking.requester?.id ?? booking.senderId;
    context.push(
      '/chat',
      extra: {
        'bookingId': booking.id,
        'tripId': tripId,
        'otherUserName': name,
        'otherUserId': otherUserId,
      },
    );
  }
}

class _BookingActionButtons extends ConsumerWidget {
  final Booking booking;
  final String tripId;
  final Set<String> ratedBookingIds;

  const _BookingActionButtons({
    required this.booking,
    required this.tripId,
    required this.ratedBookingIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tripDetailsControllerProvider(tripId).notifier);
    final localizations = localizationsOf(context, ref);

    return AnimatedSwitcher(
      duration: TripShipMotionTokens.mid, // 180ms cross-fade on status change
      switchInCurve: TripShipMotionTokens.curveInOut,
      switchOutCurve: TripShipMotionTokens.curveInOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _buildActions(context, ref, controller, localizations),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    TripDetailsController controller,
    AppLocalizations localizations,
  ) {
    // Watch for global trip loading state to disable buttons during operations
    final isLoading = ref.watch(
      tripDetailsControllerProvider(tripId).select((s) => s.isLoading),
    );

    List<Widget> topIcons = [];
    List<Widget> mainButtons = [];

    // History button
    topIcons.add(
      IconButton(
        icon: const Icon(Icons.history, color: Colors.blueGrey, size: 20),
        onPressed: isLoading
            ? null
            : () => _showOperationHistory(context, booking, localizations),
      ),
    );

    // Chat button
    topIcons.add(
      IconButton(
        icon: Icon(
          Icons.chat_bubble_outline,
          color: booking.status == BookingStatus.inCommunication
              ? Colors.orange
              : null,
          size: 20,
        ),
        onPressed: isLoading
            ? null
            : () {
                final name =
                    booking.requester?.fullName ?? localizations.unknown;
                final otherUserId = booking.requester?.id ?? booking.senderId;
                context.push(
                  '/chat',
                  extra: {
                    'bookingId': booking.id,
                    'tripId': tripId,
                    'otherUserName': name,
                    'otherUserId': otherUserId,
                  },
                );
              },
      ),
    );

    // Cancel button (only after accepted and before goods received by driver)
    if (booking.status == BookingStatus.accepted &&
        booking.goodsReceivedByDriverAt == null) {
      topIcons.add(
        IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
          tooltip: localizations.cancelBookingTitle,
          onPressed: isLoading
              ? null
              : () => _showCancelDialog(
                  context,
                  controller,
                  booking.id,
                  localizations,
                ),
        ),
      );
    }

    if (booking.status == BookingStatus.pending) {
      topIcons.add(
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green, size: 20),
          onPressed: isLoading
              ? null
              : () => _acceptBooking(
                  context,
                  controller,
                  booking.id,
                  localizations,
                ),
        ),
      );
      topIcons.add(
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red, size: 20),
          onPressed: isLoading
              ? null
              : () => controller.rejectBooking(booking.id),
        ),
      );
    } else if (booking.status == BookingStatus.accepted) {
      mainButtons.add(
        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => controller.confirmCollection(booking.id),
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(
            booking.goodsHandedBySenderAt != null
                ? localizations.handshakeConfirmPickup
                : localizations.handshakeGoodsReceived,
          ),
        ),
      );
    } else if (booking.status == BookingStatus.inTransit) {
      if (!booking.isPaid) {
        mainButtons.add(
          ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () => controller.confirmPaymentReceived(booking.id),
            icon: const Icon(Icons.lock_outline),
            label: Text(localizations.actionRequiredPayment),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
            ),
          ),
        );
      } else {
        mainButtons.add(
          Text(
            '\u2705 ${localizations.paid}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        );
      }

      if (!booking.isDelivered) {
        mainButtons.add(
          ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () => _showDeliveryDialog(
                    context,
                    controller,
                    booking.id,
                    localizations,
                  ),
            icon: const Icon(Icons.local_shipping),
            label: Text(localizations.markAsDelivered),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        );
      } else {
        mainButtons.add(
          Text(
            localizations.handshakeWaitingClient,
            style: const TextStyle(color: Colors.orange),
            textAlign: TextAlign.end,
          ),
        );
      }
    } else if (booking.status == BookingStatus.delivered) {
      mainButtons.add(
        Text(
          localizations.handshakeWaitingClient,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.end,
        ),
      );
    } else if (booking.status == BookingStatus.completed) {
      final hasRated = ratedBookingIds.contains(booking.id);
      if (!hasRated) {
        mainButtons.add(
          ElevatedButton.icon(
            key: ValueKey('cta_leave_review_${booking.id}'),
            icon: const Icon(Icons.star, color: Colors.black87, size: 18),
            label: Text(
              localizations.rateYourExperience,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: isLoading
                ? null
                : () => _showRatingDialog(
                    context,
                    controller,
                    booking,
                    localizations,
                  ),
          ),
        );
      } else {
        mainButtons.add(
          Text(
            '\u2705 ${localizations.rated}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        );
      }
    }

    return Column(
      key: ValueKey(booking.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topIcons.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: topIcons,
          ),
        if (topIcons.isNotEmpty && mainButtons.isNotEmpty)
          const SizedBox(height: 8),
        for (var i = 0; i < mainButtons.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          mainButtons[i],
        ],
      ],
    );
  }

  void _acceptBooking(
    BuildContext context,
    TripDetailsController controller,
    String bookingId,
    AppLocalizations localizations,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.warningCheckGoodsTitle,
          style: TextStyle(color: Colors.red[800]),
        ),
        content: Text(localizations.warningCheckGoodsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.acceptBookingAndProceed),
          ),
        ],
      ),
    );
    if (confirm == true) controller.acceptBooking(bookingId);
  }

  void _showRatingDialog(
    BuildContext context,
    TripDetailsController controller,
    Booking booking,
    AppLocalizations localizations,
  ) async {
    final otherUserId = booking.requester?.id ?? booking.senderId;
    if (otherUserId == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratedUserId: otherUserId,
        ratedUserRole: 'client',
        bookingId: booking.id,
      ),
    );
    if (result == true) {
      controller.addRatedBookingId(booking.id);
      controller.loadBookings();
    }
  }

  void _showDeliveryDialog(
    BuildContext context,
    TripDetailsController controller,
    String bookingId,
    AppLocalizations localizations,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const ShipmentOtpDialog(),
    );

    if (result == 'no_code') {
      controller.markDelivered(bookingId);
    } else if (result != null && result.isNotEmpty) {
      controller.markDeliveredWithOTP(bookingId, result);
    }
  }

  void _showCancelDialog(
    BuildContext context,
    TripDetailsController controller,
    String bookingId,
    AppLocalizations localizations,
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
        bookingId,
        isDriver: true,
        reason: reasonController.text.trim().isEmpty
            ? 'No reason provided'
            : reasonController.text.trim(),
      );
    }
    reasonController.dispose();
  }

  void _showOperationHistory(
    BuildContext context,
    Booking booking,
    AppLocalizations localizations,
  ) {
    final timeline = booking.timeline;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.operationHistory),
        content: SizedBox(
          width: double.maxFinite,
          child: timeline.isEmpty
              ? Center(child: Text(localizations.noHistoryYet))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: timeline.length,
                  itemBuilder: (context, index) {
                    final event = timeline[index];
                    final eventKey = event['event'] as String? ?? 'unknown';
                    final name = _getEventLabel(eventKey, localizations);

                    final at = event['at'] != null
                        ? DateTime.parse(event['at']).toLocal()
                        : event['timestamp'] != null
                        ? DateTime.parse(event['timestamp']).toLocal()
                        : null;

                    final timeStr = at != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(at)
                        : '';
                    final message = event['message'] as String? ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.blue,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (at != null)
                            Text(
                              '${localizations.eventTime}: $timeStr',
                              style: const TextStyle(fontSize: 10),
                            ),
                          if (message.isNotEmpty)
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }

  String _getEventLabel(String eventKey, AppLocalizations localizations) {
    switch (eventKey) {
      case 'offer_created':
        return localizations.eventOfferCreated;
      case 'request_created':
        return localizations.eventRequestCreated;
      case 'booking_request_created':
        return localizations.eventBookingCreated;
      case 'communication_started':
        return localizations.eventCommunicationStarted;
      case 'offer_accepted':
        return localizations.eventOfferAccepted;
      case 'offer_rejected':
        return localizations.eventOfferRejected;
      case 'booking_accepted':
        return localizations.eventBookingAccepted;
      case 'booking_rejected':
        return localizations.eventBookingRejected;
      case 'goods_handed_by_sender':
        return localizations.eventGoodsHanded;
      case 'goods_received_by_traveler':
        return localizations.eventGoodsReceived;
      case 'payment_marked_by_sender':
        return localizations.eventPaymentSent;
      case 'payment_confirmed_by_traveler':
        return localizations.eventPaymentReceived;
      case 'goods_delivered_by_traveler':
        return localizations.eventDelivered;
      case 'goods_delivered_verified_otp':
        return localizations.eventDeliveredVerifiedOtp;
      case 'goods_received_by_client':
        return localizations.eventCompleted;
      case 'booking_cancelled_by_driver':
      case 'booking_cancelled_by_user':
        return localizations.eventCancelled;
      default:
        return eventKey.replaceAll('_', ' ').toUpperCase();
    }
  }
}
