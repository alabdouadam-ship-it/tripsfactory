import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tripship/core/providers/app_mode_provider.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/widgets/support_fab.dart';
import 'package:tripship/core/utils/logger.dart';

class NotificationsScreen extends ConsumerWidget {
  static const String _logTag = 'NotificationsScreen';
  final bool hideAppBar;
  const NotificationsScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final localizations = AppLocalizations.of(context)!;

    if (user == null) {
      return Center(child: Text(localizations.pleaseLogin));
    }

    final notificationsStream = ref
        .watch(notificationServiceProvider)
        .getNotifications(user.id);

    final content = StreamBuilder<List<Map<String, dynamic>>>(
      stream: notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          StructuredLogger.error(
            _logTag,
            'Error loading notifications stream',
            snapshot.error,
          );
          return Center(child: Text(localizations.error));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 56,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noNotifications,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final isRead = isNotificationRead(notification);
            final createdAt = DateTime.parse(
              notification['created_at'],
            ).toLocal();

            final data = notification['data'];
            final isArabic =
                Localizations.localeOf(context).languageCode == 'ar';
            final originName = data != null && data is Map
                ? (isArabic ? data['origin_name_ar'] : data['origin_name_en'])
                      as String?
                : null;
            final destName = data != null && data is Map
                ? (isArabic
                          ? data['destination_name_ar']
                          : data['destination_name_en'])
                      as String?
                : null;

            final role = data != null && data is Map
                ? data['recipient_role'] as String?
                : null;
            final isSenderNotif = role == 'sender';
            final isTravelerNotif = role == 'traveler';

            return ListTile(
              tileColor: isRead
                  ? null
                  : Theme.of(context).primaryColor.withValues(alpha: 0.05),
              leading: CircleAvatar(
                backgroundColor: isRead
                    ? Colors.grey[200]
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.notifications,
                  color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      notification['title'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: isRead ? null : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  if (isSenderNotif || isTravelerNotif)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSenderNotif
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSenderNotif
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isSenderNotif
                            ? localizations.sender
                            : localizations.traveler,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSenderNotif
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                  if ((originName != null && originName.isNotEmpty) ||
                      (destName != null && destName.isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    if (originName != null && originName.isNotEmpty)
                      Text(
                        '${localizations.origin}: $originName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (destName != null && destName.isNotEmpty)
                      Text(
                        '${localizations.destination}: $destName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    DateFormat.yMMMd().add_jm().format(createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              onTap: () async {
                if (!isRead) {
                  try {
                    await ref
                        .read(notificationServiceProvider)
                        .markAsRead(notification['id'].toString());
                  } catch (e) {
                    StructuredLogger.error(
                      _logTag,
                      'Failed to mark notification as read',
                      e,
                    );
                  }
                }
                if (!context.mounted) return;
                final data = notification['data'];
                if (data != null && data is Map) {
                  _handleNavigation(
                    context,
                    ref,
                    Map<dynamic, dynamic>.from(data),
                  );
                }
              },
            );
          },
        );
      },
    );

    if (hideAppBar) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.notifications),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: localizations.markAllRead,
            onPressed: () async {
              try {
                await ref
                    .read(notificationServiceProvider)
                    .markAllAsRead(user.id);
              } catch (e) {
                StructuredLogger.error(
                  _logTag,
                  'Failed to mark all notifications as read',
                  e,
                );
              }
            },
          ),
        ],
      ),
      body: content,
      floatingActionButton: const SupportFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _handleNavigation(
    BuildContext context,
    WidgetRef ref,
    Map<dynamic, dynamic> data,
  ) {
    // 0. Context-Aware Profile Flipping
    final role = data['recipient_role']?.toString();
    if (role == 'sender') {
      ref.read(isClientModeProvider.notifier).setMode(true);
    } else if (role == 'traveler') {
      ref.read(isClientModeProvider.notifier).setMode(false);
    }

    // Normalize keys
    final type = data['type']?.toString();
    final bookingId = data['booking_id'] ?? data['bookingId'];
    final tripId = data['trip_id'] ?? data['tripId'];
    final shipmentId = data['shipment_id'] ?? data['shipmentId'];
    final ticketId = data['ticket_id'] ?? data['ticketId'];
    final otherUserName = data['other_user_name'] ?? data['otherUserName'];
    final otherUserId = data['other_user_id'] ?? data['otherUserId'];

    // 1. Chat — only for message-type notifications
    if (type == 'support_reply') {
      context.push(
        AppRoutes.support,
        extra: {if (ticketId != null) 'focusTicketId': ticketId.toString()},
      );
      return;
    }

    if (type == 'new_message' && bookingId != null) {
      context.push(
        '/chat',
        extra: {
          'bookingId': bookingId,
          'tripId': tripId,
          'driverId': data['traveler_id'] ?? data['driverId'],
          'otherUserName': otherUserName ?? '',
          'otherUserId': otherUserId ?? 'unknown',
        },
      );
      return;
    }

    // 2. Trip Details
    if (tripId != null) {
      context.push('${AppRoutes.tripDetails}?id=$tripId');
      return;
    }

    // 3. Offer Details - prioritized for traveler view
    final offerId = data['offer_id'] ?? data['offerId'];
    if (offerId != null) {
      context.push('${AppRoutes.offerDetails}?id=$offerId');
      return;
    }

    // 4. Shipment Details
    if (shipmentId != null) {
      context.push('${AppRoutes.shipmentDetails}?id=$shipmentId');
      return;
    }

    // 4. Fallback: booking with chat info or my-requests
    if (bookingId != null) {
      if (otherUserName != null && otherUserName.toString().isNotEmpty) {
        context.push(
          '/chat',
          extra: {
            'bookingId': bookingId,
            'otherUserName': otherUserName,
            'otherUserId': otherUserId ?? 'unknown',
          },
        );
      } else {
        // No user info available — navigate to activity screen
        context.go(AppRoutes.myAlerts);
      }
    }
  }
}
