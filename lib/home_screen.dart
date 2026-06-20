import 'dart:async';
import 'package:tripship/core/config/app_routes.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:flutter/material.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/providers/app_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripship/core/widgets/draggable_floating_button.dart';
import 'package:tripship/core/widgets/ad_banner.dart';
import 'package:tripship/core/services/ad_service.dart';
import 'package:tripship/core/services/app_review_service.dart';
import 'package:tripship/core/services/app_config_service.dart';
import 'package:tripship/core/widgets/support_fab.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/widgets/top_announcement_banner.dart';
import 'package:tripship/core/widgets/first_launch_popup_gate.dart';
import 'package:tripship/core/widgets/occasional_popup_gate.dart';
import 'package:tripship/core/widgets/account_suspended_banner.dart';
import 'package:tripship/features/trips/presentation/private_drivers_page.dart';
import 'package:tripship/features/home/presentation/widgets/home_app_bar.dart';
import 'package:tripship/features/home/presentation/widgets/home_selection_cards.dart';
import 'package:tripship/features/home/presentation/widgets/home_dialogs.dart';
import 'package:tripship/features/home/presentation/home_filters.dart';
import 'package:tripship/features/trips/presentation/trip_list_view.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/home/presentation/providers/home_filter_provider.dart';
import 'package:tripship/features/home/presentation/widgets/home_context_bar.dart';

// Screens for Navigation
import 'package:tripship/features/bookings/presentation/my_requests_screen.dart';
import 'package:tripship/features/trips/presentation/my_trips_screen.dart';
import 'package:tripship/features/profile/presentation/profile_screen.dart';
import 'package:tripship/features/home/presentation/notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _logTag = 'HomeScreen';
  String _travelerStatus = DomainConfig.statusNone; // none, pending, approved, rejected
  int _selectedIndex = 0; // Tab Index
  TransportType _selectedTransport = TransportType.none;

  final GlobalKey<HomeFiltersState> _homeFiltersKey = GlobalKey();
  List<Location> _locations = [];

  String? _globalMessageContent;

  Future<void> _checkGlobalMessage() async {
    try {
      final config = await ref.read(appConfigProvider.future);
      if (config.globalMessageActive &&
          config.globalMessageContent != null &&
          config.globalMessageContent!.isNotEmpty) {
        final prefs = ref.read(preferencesServiceProvider);
        final lastSeenHash = await prefs.getInt(
          'last_seen_global_message_hash',
        );
        final currentHash = config.globalMessageContent.hashCode;

        // If message is different from what user last seen, show it.
        if (lastSeenHash != currentHash) {
          if (mounted) {
            setState(() {
              _globalMessageContent = config.globalMessageContent;
            });
          }
        }
      }
    } catch (e) {
      StructuredLogger.error(_logTag, 'Error checking global message', e);
    }
  }

  Future<void> _dismissGlobalMessage() async {
    if (_globalMessageContent == null) return;
    final content = _globalMessageContent!;
    setState(() => _globalMessageContent = null);

    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setInt('last_seen_global_message_hash', content.hashCode);
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;
    try {
      final result = await ref.read(tripRepositoryProvider).getLocations();
      final locs = result.fold((value) => value, (error) => throw error);
      if (mounted) {
        setState(() => _locations = locs);
      }
    } catch (e) {
      StructuredLogger.error(_logTag, 'Error loading locations', e);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    // ignore: unused_result
    ref.refresh(currentUserProfileProvider);
    StructuredLogger.info(_logTag, 'Refreshing user data');
    // ignore: unused_result
    ref.refresh(activeAdsProvider);
    // Status is read from profile provider — no separate DB calls needed
    _syncStatusFromProfile();
    if (!mounted) return;
    await _loadLocations();
  }

  /// Reads traveler status directly from the already-fetched profile.
  void _syncStatusFromProfile() {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null || !mounted) return;
    setState(() {
      _travelerStatus = profile.travelerStatus;
    });
  }

  @override
  void initState() {
    super.initState();

    // Default for traveler: no transport selected
    if (!ref.read(isClientModeProvider)) {
      _selectedTransport = TransportType.none;
    }

    // Read status directly from profile provider — no extra DB calls
    _syncStatusFromProfile();
    _loadLocations();
    // Fire-and-forget; no need to await.
    // ignore: unused_result
    ref.refresh(activeAdsProvider);
    ref.read(appReviewServiceProvider).maybeRequestReview();

    // Check and show global announcement if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGlobalMessage();
      // Re-sync status once profile finishes loading (it may be async)
      ref.listenManual(
        currentUserProfileProvider,
        (_, next) => next.whenData((_) => _syncStatusFromProfile()),
        fireImmediately: true,
      );

      // Initialize transport type in provider
      if (ref.read(isClientModeProvider)) {
        ref
            .read(clientFilterProvider.notifier)
            .setTransportType(_selectedTransport);
      } else {
        ref
            .read(travelerFilterProvider.notifier)
            .setTransportType(_selectedTransport);
      }
    });
  }

  Future<void> _confirmSwitchMode(bool newValue) async {
    // If switching TO Driver Mode (newValue == false)
    if (newValue == false) {
      final profile = ref.read(currentUserProfileProvider).value;
      StructuredLogger.info(
        _logTag,
        'Switching to Driver Mode. Profile status: ${profile?.travelerStatus}',
      );
      if (profile?.travelerStatus != DomainConfig.statusApproved) {
        if (profile?.travelerStatus == DomainConfig.statusPending) {
          HomeDialogs.showApplicationPending(context);
        } else {
          HomeDialogs.showRegistrationRequired(context, status: profile?.travelerStatus);
        }
        return; // Block switch
      }
    }

    final confirm = await HomeDialogs.showSwitchModeConfirm(
      context,
      toClientMode: newValue,
    );

    if (confirm == true) {
      ref.read(isClientModeProvider.notifier).setMode(newValue);
      setState(() {
        _selectedTransport = TransportType.none;
        _loadData();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isClientMode = ref.watch(isClientModeProvider);

    // Build tabs dynamically
    final List<Widget> widgetOptions = [];
    final List<NavigationDestination> destinations = [];

    // 1. Home
    widgetOptions.add(
      _buildHomeTab(context, localizations, theme, isClientMode),
    );
    destinations.add(
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: localizations.home,
      ),
    );

    // 2. My Requests / My Trips
    if (isClientMode) {
      widgetOptions.add(const MyRequestsScreen());
      destinations.add(
        NavigationDestination(
          icon: const Icon(Icons.request_page_outlined),
          selectedIcon: const Icon(Icons.request_page),
          label: localizations.myRequests,
        ),
      );
    } else {
      widgetOptions.add(const MyTripsScreen());
      destinations.add(
        NavigationDestination(
          icon: const Icon(Icons.person_pin_outlined),
          selectedIcon: const Icon(Icons.person_pin),
          label: localizations.myTrips,
        ),
      );
    }

    // 3. Profile
    widgetOptions.add(const ProfileScreen());
    destinations.add(
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: localizations.myProfile,
      ),
    );

    // Safety check for index
    if (_selectedIndex >= widgetOptions.length) {
      _selectedIndex = 0;
    }

    final profileForPopup = ref.watch(currentUserProfileProvider).valueOrNull;
    final isDriver =
        (profileForPopup?.travelerStatus ?? DomainConfig.statusNone) != DomainConfig.statusNone;
    final isNewUser = profileForPopup?.createdAt != null &&
        DateTime.now().difference(profileForPopup!.createdAt!).inDays < 7;

    return OccasionalPopupGate(
      isDriver: isDriver,
      isNewUser: isNewUser,
      child: FirstLaunchPopupGate(
        isDriver: isDriver,
        isNewUser: isNewUser,
        child: Scaffold(
          body: widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: destinations,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
    bool isClientMode,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              children: [
                if (_globalMessageContent != null)
                  TopAnnouncementBanner(
                    message: _globalMessageContent!,
                    onDismiss: () => unawaited(_dismissGlobalMessage()),
                  ),
                Consumer(
                  builder: (context, ref, child) {
                    final profile = ref.watch(currentUserProfileProvider).value;
                    if (profile == null) return const SizedBox.shrink();

                    final isGlobalSuspended = profile.isSuspended;
                    final isModeSuspended = isClientMode
                        ? false
                        : profile.travelerStatus == DomainConfig.statusSuspended;

                    if (isGlobalSuspended || isModeSuspended) {
                      return const AccountSuspendedBanner();
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      HomeAppBar(
                        isClientMode: isClientMode,
                        selectedTransport: _selectedTransport,
                        travelerStatus: _travelerStatus,
                        selectedIndex: _selectedIndex,
                        onBackPressed: () => setState(
                          () => _selectedTransport = TransportType.none,
                        ),
                        onModeSwitchRequested: _confirmSwitchMode,
                        onAdvancedFiltersTapped: () => _homeFiltersKey
                            .currentState
                            ?.showAdvancedFiltersDialog(),
                      ),
                      if (isClientMode &&
                          _selectedTransport == TransportType.none)
                        _buildAdSliver(),
                      SliverToBoxAdapter(
                        child:
                            (isClientMode &&
                                _selectedTransport == TransportType.none)
                            ? HomeSelectionCards(
                                onInternalTapped: () => setState(
                                  () => _selectedTransport =
                                      TransportType.internal,
                                ),
                                onExternalTapped: () => setState(
                                  () => _selectedTransport =
                                      TransportType.external,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (isClientMode &&
                          _selectedTransport != TransportType.none)
                        SliverFillRemaining(
                          child: Column(
                            children: [
                              HomeContextBar(
                                isClientMode: isClientMode,
                                isInternal:
                                    _selectedTransport == TransportType.internal,
                                locations: _locations,
                                homeFiltersKey: _homeFiltersKey,
                                filterProvider: clientFilterProvider,
                              ),
                              Expanded(
                                child:
                                    (_selectedTransport ==
                                                TransportType.internal ||
                                            _selectedTransport ==
                                                TransportType.external)
                                        ? TripListView(
                                            isInternal:
                                                _selectedTransport ==
                                                TransportType.internal,
                                            filterProvider: clientFilterProvider,
                                          )
                                        : const PrivateTravelersPage(),
                              ),
                            ],
                          ),
                        ),
                      if (!isClientMode)
                        const SliverFillRemaining(
                          child: NotificationsScreen(hideAppBar: true),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Builder(
              builder: (context) {
                final fab = _getFabWidget(localizations, isClientMode, context);
                if (fab == null) return const SizedBox.shrink();
                return DraggableFloatingButton(
                  initialOffset: Offset(20, constraints.maxHeight - 80),
                  parentWidth: constraints.maxWidth,
                  parentHeight: constraints.maxHeight,
                  onPressed: () {},
                  child: fab,
                );
              },
            ),
            if (_selectedTransport == TransportType.none)
              Positioned(left: 20, bottom: 20, child: const SupportFab()),
          ],
        );
      },
    );
  }

  Widget _buildAdSliver() {
    final adsAsync = ref.watch(activeAdsProvider);
    return SliverToBoxAdapter(
      child: adsAsync.maybeWhen(
        data: (ads) {
          if (ads.isEmpty) return const SizedBox.shrink();
          final ad = ads.first;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AdBanner(
              imageUrl: ad['image_url'],
              clickUrl: ad['click_url'],
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget? _getFabWidget(
    AppLocalizations localizations,
    bool isClientMode,
    BuildContext context,
  ) {
    if (isClientMode) {
      // Senders browse trips and request via trip details — no home FAB.
      return null;
    }

    // Driver mode: post a trip.
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile?.isDriverValid ?? false) {
      return FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.postTrip),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.local_shipping),
        label: Text(localizations.postTrip),
      );
    }
    return null;
  }
}
