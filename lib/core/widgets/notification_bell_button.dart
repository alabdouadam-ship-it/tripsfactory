import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tripsfactory/core/providers/app_mode_provider.dart';
import 'package:tripsfactory/core/services/notification_service.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';

/// Bell icon button that shows a floating panel with global notifications.
class NotificationBellButton extends ConsumerWidget {
  /// Icon color - use Colors.white for dark app bars
  final Color? iconColor;

  const NotificationBellButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final count = unreadCount.valueOrNull ?? 0;

    final theme = Theme.of(context); // Added to access theme.colorScheme

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: iconColor),
          if (count > 0)
            Positioned(
              top: 8, // Changed from -2
              right: 8, // Changed from -2
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  // Changed to BoxDecoration to use theme
                  color: theme.colorScheme.error, // Changed from Colors.red
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count', // Kept original logic for text
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => _showNotificationPanel(context, ref, user.id),
      tooltip: AppLocalizations.of(context)!.notifications,
    );
  }

  void _showNotificationPanel(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final notificationsStream = ref
        .read(notificationServiceProvider)
        .getNotifications(userId);
    final localizations = AppLocalizations.of(context)!;

    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) =>
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: notificationsStream,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(localizations.error));
                }
                final notifications = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.notifications,
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.done_all),
                            tooltip: localizations.markAllRead,
                            onPressed: notifications.isEmpty
                                ? null
                                : () async {
                                    final nav = ref.read(
                                      notificationServiceProvider,
                                    );
                                    for (final n in notifications) {
                                      if (!isNotificationRead(n)) {
                                        final id = n['id'];
                                        if (id != null) {
                                          await nav.markAsRead(id.toString());
                                        }
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    localizations.noNotifications,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : Builder(
                              builder: (_) {
                                final unread = notifications
                                    .where((n) => !isNotificationRead(n))
                                    .toList();
                                final read = notifications
                                    .where((n) => isNotificationRead(n))
                                    .toList();
                                return ListView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.only(bottom: 80),
                                  children: [
                                    ...unread.map(
                                      (n) => _NotificationTile(
                                        notification: n,
                                        ref: ref,
                                        parentContext: parentContext,
                                        modalContext: ctx,
                                      ),
                                    ),
                                    if (read.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          localizations.readNotifications,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      ...read.map(
                                        (n) => _NotificationTile(
                                          notification: n,
                                          ref: ref,
                                          parentContext: parentContext,
                                          modalContext: ctx,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          parentContext.push('/notifications');
                                        },
                                        icon: const Icon(Icons.list),
                                        label: Text(
                                          localizations.seeAllNotifications,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final WidgetRef ref;
  final BuildContext parentContext;
  final BuildContext modalContext;

  const _NotificationTile({
    required this.notification,
    required this.ref,
    required this.parentContext,
    required this.modalContext,
  });

  void _handleNavigation(BuildContext context, Map<dynamic, dynamic> data) {
    // 0. Context-Aware Profile Flipping
    final role = data['recipient_role']?.toString();
    if (role == 'sender') {
      ref.read(isClientModeProvider.notifier).setMode(true);
    } else if (role == 'traveler') {
      ref.read(isClientModeProvider.notifier).setMode(false);
    }

    final type = data['type']?.toString();
    final bookingId = data['booking_id'] ?? data['bookingId'];
    final tripId = data['trip_id'] ?? data['tripId'];
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

    // 3. Fallback: booking with chat info
    if (bookingId != null &&
        otherUserName != null &&
        otherUserName.toString().isNotEmpty) {
      context.push(
        '/chat',
        extra: {
          'bookingId': bookingId,
          'otherUserName': otherUserName,
          'otherUserId': otherUserId ?? 'unknown',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = isNotificationRead(notification);
    final createdAt = DateTime.parse(notification['created_at']).toLocal();
    final data = notification['data'];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final originName = data != null && data is Map
        ? (isArabic ? data['origin_name_ar'] : data['origin_name_en'])
              as String?
        : null;
    final destName = data != null && data is Map
        ? (isArabic ? data['destination_name_ar'] : data['destination_name_en'])
              as String?
        : null;

    final role = data != null && data is Map
        ? data['recipient_role'] as String?
        : null;
    final isSenderNotif = role == 'sender';
    final isTravelerNotif = role == 'traveler';

    final loc = AppLocalizations.of(context)!;

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
          size: 20,
        ),
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              notification['title'] ?? '',
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (isSenderNotif || isTravelerNotif) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSenderNotif
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSenderNotif
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isSenderNotif ? loc.sender : loc.traveler,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSenderNotif ? Colors.blue[700] : Colors.green[700],
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            notification['body'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if ((originName != null && originName.isNotEmpty) ||
              (destName != null && destName.isNotEmpty)) ...[
            const SizedBox(height: 6),
            if (originName != null && originName.isNotEmpty)
              Text(
                '${loc.origin}: $originName',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (destName != null && destName.isNotEmpty)
              Text(
                '${loc.destination}: $destName',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormat.yMMMd().add_jm().format(createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      onTap: () async {
        if (!isRead) {
          await ref
              .read(notificationServiceProvider)
              .markAsRead(notification['id'].toString());
        }
        if (!modalContext.mounted) return;
        final data = notification['data'];
        if (data != null && data is Map) {
          Navigator.pop(modalContext);
          if (parentContext.mounted) {
            _handleNavigation(parentContext, Map<dynamic, dynamic>.from(data));
          }
        }
      },
    );
  }
}
