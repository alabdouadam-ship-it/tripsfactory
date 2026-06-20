import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:tripsfactory/core/config/domain_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/features/trips/presentation/trip_card.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/utils/error_utils.dart';
import 'package:tripsfactory/core/widgets/empty_state_widget.dart';
import 'package:tripsfactory/core/widgets/tripsfactory_error_view.dart';
import 'package:tripsfactory/core/widgets/tripsfactory_dialog.dart';
import 'package:tripsfactory/core/services/share_service.dart';
import 'package:tripsfactory/features/trips/presentation/providers/my_trips_provider.dart';
import 'package:tripsfactory/core/utils/logger.dart';

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  Widget _chip(
    TripFilter f,
    String label,
    TripFilter currentFilter,
    WidgetRef ref,
    BuildContext context,
  ) {
    final isSelected = currentFilter == f;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => ref.read(myTripsFilterProvider.notifier).state = f,
        backgroundColor: theme.cardColor,
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : theme.hintColor,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text(localizations.pleaseLogin)));
    }

    final isApprovedTraveler =
        ref.watch(
          currentUserProfileProvider.select((p) => p.value?.travelerStatus),
        ) ==
        DomainConfig.statusApproved;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final currentFilter = ref.watch(myTripsFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.myTrips)),
      floatingActionButton: isApprovedTraveler
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.postTrip),
              label: Text(localizations.postTrip),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.local_shipping),
            )
          : null,
      body: Column(
        children: [
          // ── Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(
                  TripFilter.all,
                  isArabic ? 'الكل' : 'All',
                  currentFilter,
                  ref,
                  context,
                ),
                _chip(
                  TripFilter.available,
                  isArabic ? 'متاحة' : 'Available',
                  currentFilter,
                  ref,
                  context,
                ),
                _chip(
                  TripFilter.full,
                  isArabic ? 'ممتلئة' : 'Full',
                  currentFilter,
                  ref,
                  context,
                ),
                _chip(
                  TripFilter.completed,
                  isArabic ? 'مكتملة' : 'Completed',
                  currentFilter,
                  ref,
                  context,
                ),
                _chip(
                  TripFilter.cancelled,
                  isArabic ? 'ملغاة' : 'Cancelled',
                  currentFilter,
                  ref,
                  context,
                ),
              ],
            ),
          ),
          Expanded(
            child: ref
                .watch(filteredMyTripsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) {
                    StructuredLogger.error(
                      'MyTripsScreen',
                      'Error loading trips',
                      error,
                      stackTrace,
                    );
                    return TripsFactoryErrorView(
                      title: localizations.unexpectedError,
                      message: getUserFriendlyMessage(
                        error,
                        localizations.unexpectedError,
                        context,
                      ),
                      onRetry: () => ref.invalidate(myTripsProvider),
                    );
                  },
                  data: (trips) {
                    if (trips.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.directions_car_filled_outlined,
                        title: localizations.noTripsFound,
                        message: '',
                      );
                    }
                    return ListView.builder(
                      itemCount: trips.length,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return TripCard(
                          trip: trip,
                          onTap: () =>
                              context.push(AppRoutes.tripDetails, extra: trip),
                          onCopyTrip: () =>
                              context.push(AppRoutes.postTrip, extra: trip),
                          onDelete: trip.status != TripStatus.cancelled
                              ? () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => TripsFactoryDialog(
                                      title: localizations.cancelTrip,
                                      content: localizations.confirmCancelTrip,
                                      cancelLabel: localizations.cancel,
                                      confirmLabel: localizations.confirm,
                                      isDestructive: true,
                                      icon: Icons.cancel_outlined,
                                      onCancel: () => context.pop(false),
                                      onConfirm: () => context.pop(true),
                                    ),
                                  );

                                  if (confirm == true) {
                                    ref
                                        .read(myTripsProvider.notifier)
                                        .cancelTrip(trip.id);
                                  }
                                }
                              : null,
                          onShareTrip: () => shareTrip(trip.id),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
