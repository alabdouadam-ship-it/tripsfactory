import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/trips/presentation/trip_card.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/widgets/empty_state_widget.dart';
import 'package:tripship/core/widgets/skeleton_loader.dart';
import 'package:tripship/core/services/share_service.dart';
import 'package:tripship/features/trips/data/route_alert_service.dart';
import 'package:tripship/features/trips/presentation/providers/trip_list_provider.dart';

import 'package:tripship/features/home/presentation/providers/home_filter_provider.dart';

class TripListView extends ConsumerStatefulWidget {
  final bool isInternal;
  final NotifierProvider<HomeFilterNotifier, HomeFilterState> filterProvider;

  const TripListView({
    super.key,
    required this.isInternal,
    required this.filterProvider,
  });

  @override
  ConsumerState<TripListView> createState() => _TripListViewState();
}

class _TripListViewState extends ConsumerState<TripListView> {
  final ScrollController _scrollController = ScrollController();

  TripListFilter get _currentFilter {
    return TripListFilter(
      isInternal: widget.isInternal,
      filterState: ref.read(widget.filterProvider),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(tripListProvider(_currentFilter).notifier).loadMoreTrips();
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    // Invalidate the provider to force a fresh `build` (which triggers _loadInitialTrips)
    ref.invalidate(tripListProvider(_currentFilter));
  }

  bool get _hasOriginAndDest {
    final filterState = ref.read(widget.filterProvider);
    final hasOrigin =
        filterState.originLocationId != null ||
        (filterState.originProvince != null &&
            filterState.originProvince!.isNotEmpty) ||
        (filterState.originCity != null && filterState.originCity!.isNotEmpty);
    final hasDest =
        filterState.destLocationId != null ||
        (filterState.destProvince != null &&
            filterState.destProvince!.isNotEmpty) ||
        (filterState.destinationCity != null &&
            filterState.destinationCity!.isNotEmpty);
    return hasOrigin && hasDest;
  }

  Future<void> _createRouteAlert() async {
    if (!_hasOriginAndDest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.alertRequiresOriginAndDest,
          ),
        ),
      );
      return;
    }

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseLogin)),
      );
      return;
    }

    try {
      final filterState = ref.read(widget.filterProvider);
      await ref
          .read(routeAlertServiceProvider)
          .createAlert(
            userId: user.id,
            originLocationId: filterState.originLocationId,
            destLocationId: filterState.destLocationId,
            originProvince: filterState.originProvince,
            destProvince: filterState.destProvince,
            originCity: filterState.originCity,
            destCity: filterState.destinationCity,
            isInternal: widget.isInternal,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.alertCreated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unexpectedError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Watch the filter so this view rebuilds and re-keys the list provider
    // the instant the user changes origin/destination (live filtering).
    // Previously this used ref.listen + a ref.read filter, which did not
    // rebuild the widget — so the new filter only took effect after leaving
    // and returning to the page.
    final filterState = ref.watch(widget.filterProvider);
    final currentFilter = TripListFilter(
      isInternal: widget.isInternal,
      filterState: filterState,
    );

    final tripListAsync = ref.watch(tripListProvider(currentFilter));

    return tripListAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => const TripCardSkeleton(),
      ),
      error: (error, _) {
        final fallback = localizations.unexpectedError;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(getUserFriendlyMessage(error, fallback, context)),
              TextButton(onPressed: _refresh, child: Text(localizations.retry)),
            ],
          ),
        );
      },
      data: (state) {
        if (state.trips.isEmpty) {
          return EmptyStateWidget(
            title: localizations.noTripsFound,
            message: '',
            icon: Icons.directions_car_outlined,
            onActionPressed: () {
              HapticFeedback.selectionClick();
              _refresh();
            },
            actionLabel: localizations.retry,
            onSecondaryActionMessage: _hasOriginAndDest
                ? localizations.alertMeWhenAvailable
                : null,
            onSecondaryActionPressed: _hasOriginAndDest
                ? _createRouteAlert
                : null,
            secondaryActionLabel: _hasOriginAndDest
                ? localizations.alertMe
                : null,
            onTertiaryActionPressed: () => context.push(AppRoutes.myAlerts),
            tertiaryActionLabel: localizations.myAlerts,
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.showCachedBanner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.amber.shade100,
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 20,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.showingCachedData,
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.trips.length + (state.hasMore ? 1 : 0),
                  padding: const EdgeInsets.only(
                    bottom: 80,
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  itemBuilder: (context, index) {
                    if (index == state.trips.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final trip = state.trips[index];
                    return TripCard(
                      trip: trip,
                      delay: (index * 50).ms,
                      bookingStatus: state.bookingStatuses[trip.id],
                      onTap: () {
                        context.push(AppRoutes.tripDetails, extra: trip).then((
                          _,
                        ) {
                          ref
                              .read(tripListProvider(_currentFilter).notifier)
                              .refreshBookingStatusForTrip(trip);
                        });
                      },
                      onShareTrip: () => shareTrip(trip.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
