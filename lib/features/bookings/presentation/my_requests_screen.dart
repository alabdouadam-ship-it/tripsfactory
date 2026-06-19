import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/widgets/notification_bell_button.dart';
import 'package:tripship/features/trips/presentation/trip_card.dart';
import 'package:tripship/core/services/share_service.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  BookingStatus? _selectedFilter;

  Stream<List<Booking>> _watchMyRequests() {
    return ref.read(bookingRepositoryProvider).watchMyRequests().map((result) {
      return result.fold((bookings) => bookings, (error) => throw error);
    });
  }

  List<Booking> _applyFilter(List<Booking> allRequests) {
    if (_selectedFilter == null) return List.from(allRequests);
    final filtered = allRequests
        .where((b) => b.status == _selectedFilter)
        .toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  void _onFilterChanged(BookingStatus? status) {
    setState(() => _selectedFilter = status);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myRequests),
        actions: const [NotificationBellButton()],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, loc.all),
                const SizedBox(width: 8),
                _buildFilterChip(BookingStatus.pending, loc.statusPending),
                const SizedBox(width: 8),
                _buildFilterChip(BookingStatus.accepted, loc.statusAccepted),
                const SizedBox(width: 8),
                _buildFilterChip(BookingStatus.inTransit, loc.statusPickedUp),
                const SizedBox(width: 8),
                _buildFilterChip(BookingStatus.delivered, loc.statusDelivered),
                const SizedBox(width: 8),
                _buildFilterChip(BookingStatus.rejected, loc.statusRejected),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _watchMyRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allRequests = snapshot.data ?? [];
                final filteredRequests = _applyFilter(allRequests);
                if (filteredRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: Theme.of(
                            context,
                          ).hintColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.noShipmentsFound,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final booking = filteredRequests[index];
                    final trip = booking.trip;
                    if (trip == null) return const SizedBox.shrink();
                    return TripCard(
                      trip: trip,
                      onTap: () => context.push(AppRoutes.tripDetails, extra: trip),
                      bookingStatus: booking.status,
                      requestedAt: booking.createdAt,
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

  Widget _buildFilterChip(BookingStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(status),
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
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
    );
  }
}
