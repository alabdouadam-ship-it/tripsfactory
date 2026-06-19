import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:tripship/core/providers/app_mode_provider.dart';
import 'package:tripship/core/widgets/notification_bell_button.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// Extracted SliverAppBar from HomeScreen.
/// Handles gradient header, mode switch, tab bar, title, and actions.
class HomeAppBar extends ConsumerWidget {
  final bool isClientMode;
  final TransportType selectedTransport;
  final String travelerStatus;
  final int selectedIndex;
  final TabController? travelerTabController;
  final VoidCallback onBackPressed;
  final ValueChanged<bool> onModeSwitchRequested;
  final VoidCallback? onAdvancedFiltersTapped;
  final GlobalKey? homeFiltersKey;

  const HomeAppBar({
    super.key,
    required this.isClientMode,
    required this.selectedTransport,
    required this.travelerStatus,
    required this.selectedIndex,
    this.travelerTabController,
    required this.onBackPressed,
    required this.onModeSwitchRequested,
    this.onAdvancedFiltersTapped,
    this.homeFiltersKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    String titleText = localizations.appTitle;

    // Dynamic Title based on selection
    if (isClientMode) {
      if (selectedTransport == TransportType.internal) {
        titleText = localizations.internalTrips;
      } else if (selectedTransport == TransportType.external) {
        titleText = localizations.externalTrips;
      }
    }
    if (!isClientMode && selectedIndex == 0) {
      final profile = ref.watch(currentUserProfileProvider).value;
      if (profile?.travelerStatus == DomainConfig.statusApproved) {
        if (profile?.isDriver ?? false) {
          final i = travelerTabController?.index ?? 0;
          if (i == 0) {
            titleText = localizations.notifications;
          } else if (i == 1) {
            titleText = localizations.internalRequests;
          } else if (i == 2) {
            titleText = localizations.externalRequests;
          }
        } else {
          titleText = localizations.notifications;
        }
      } else {
        titleText = localizations.notifications;
      }
    }

    return SliverAppBar(
      expandedHeight: 90.0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: isClientMode && selectedTransport != TransportType.none
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed,
            )
          : null,
      leadingWidth: isClientMode && selectedTransport != TransportType.none
          ? null
          : 0,
      title: Text(
        titleText,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottom:
          (!isClientMode && selectedIndex == 0 && travelerStatus == DomainConfig.statusApproved)
          ? TabBar(
              controller: travelerTabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: localizations.notifications),
                Tab(text: localizations.internalRequests),
                Tab(text: localizations.externalRequests),
              ],
            )
          : null,
      actions: [
        if (isClientMode) NotificationBellButton(iconColor: Colors.white),
        if (!isClientMode && selectedIndex == 0) ...[
          Consumer(
            builder: (context, ref, _) {
              final profile = ref.watch(currentUserProfileProvider).value;
              final isApproved = profile?.travelerStatus == DomainConfig.statusApproved;
              final showMarkAll =
                  !isApproved || (travelerTabController?.index ?? 0) == 0;

              if (showMarkAll) {
                return IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  tooltip: localizations.markAllRead,
                  onPressed: () async {
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null) {
                      await ref
                          .read(notificationServiceProvider)
                          .markAllAsRead(user.id);
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        if (isClientMode &&
            (selectedTransport == TransportType.internal ||
                selectedTransport == TransportType.external))
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: onAdvancedFiltersTapped,
          ),
        Row(
          children: [
            Text(
              ref.watch(isClientModeProvider)
                  ? localizations.iAmSender
                  : localizations.iAmTraveler,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: ref.watch(isClientModeProvider),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              onChanged: onModeSwitchRequested,
            ),
          ],
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  Icons.local_shipping,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
