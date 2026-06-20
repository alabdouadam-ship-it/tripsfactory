import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/services/share_service.dart';
import 'package:tripsfactory/core/widgets/skeleton_loader.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/features/bookings/data/booking_model.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/presentation/trip_card.dart';
import 'package:tripsfactory/features/trips/presentation/controllers/trip_details_controller.dart';
import 'package:tripsfactory/features/trips/presentation/controllers/trip_details_state.dart';
import 'package:tripsfactory/features/trips/presentation/widgets/trip_bookings_list.dart';
import 'package:tripsfactory/features/trips/presentation/widgets/trip_management_buttons.dart';
import 'package:tripsfactory/features/trips/presentation/widgets/trip_sender_section.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final Trip? trip;
  final String? tripId;

  const TripDetailsScreen({super.key, this.trip, this.tripId});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  bool _initialized = false;

  String get _resolvedTripId => widget.trip?.id ?? widget.tripId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialized());
  }

  @override
  void didUpdateWidget(covariant TripDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.trip?.id ?? oldWidget.tripId ?? '';
    final newId = _resolvedTripId;
    if (oldId != newId) {
      _initialized = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialized());
    }
  }

  void _ensureInitialized() {
    if (!mounted || _initialized) return;
    if (_resolvedTripId.isEmpty) return;

    _initialized = true;
    ref
        .read(tripDetailsControllerProvider(_resolvedTripId).notifier)
        .init(widget.trip, widget.tripId);
  }

  bool _hasActiveClientBooking(Booking? booking) {
    if (booking == null) return false;
    if (booking.status == BookingStatus.inCommunication) return false;
    if (booking.status == BookingStatus.rejected) return true;

    return booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.completed;
  }

  bool _cannotCancelTrip(List<Booking> bookings) {
    return bookings.any(
      (b) =>
          b.status == BookingStatus.completed ||
          b.goodsReceivedByDriverAt != null ||
          b.paymentConfirmedByDriverAt != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final tripId = _resolvedTripId;

    final state = ref.watch(tripDetailsControllerProvider(tripId));
    final controller = ref.read(tripDetailsControllerProvider(tripId).notifier);

    ref.listen<String?>(
      tripDetailsControllerProvider(tripId).select((s) => s.error),
      (previous, next) {
        if (next != null && next != previous && mounted) {
          final translated = next == 'cannot_book_blocked' 
              ? localizations.cannotBookBlockedUser 
              : next;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(translated)));
        }
      },
    );

    final trip = state.trip;
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final isOwner = trip != null && currentUser?.id == trip.driverId;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.tripDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRoutes.home),
          ),
          if (trip != null && !isOwner)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: localizations.shareTrip,
              onPressed: () => shareTrip(trip.id),
            ),
        ],
      ),
      body: _buildBody(
        context,
        state,
        localizations,
        trip,
        isOwner,
        tripId,
        controller,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TripDetailsState state,
    AppLocalizations localizations,
    Trip? trip,
    bool isOwner,
    String tripId,
    TripDetailsController controller,
  ) {
    if (tripId.isEmpty || (trip == null && !state.isLoading)) {
      return Center(child: Text(localizations.error));
    }

    if (state.isLoading && trip == null) {
      return const TripDetailsSkeleton();
    }

    if (trip == null) {
      return Center(child: Text(localizations.error));
    }

    final hasActiveBooking = _hasActiveClientBooking(state.userBooking);
    final cannotCancel = _cannotCancelTrip(state.bookings);

    return SafeArea(
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TripHeroImage(trip: trip),
              const SizedBox(height: 16),
              TripCard(trip: trip, margin: EdgeInsets.zero),
              const SizedBox(height: 24),
              if (isOwner) ...[
                Text(
                  localizations.bookingsRequests,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (state.isLoadingBookings)
                  const Center(child: CircularProgressIndicator())
                else
                  TripBookingsList(
                    tripId: trip.id,
                    bookings: state.bookings,
                    ratedBookingIds: state.ratedBookingIds,
                    localizations: localizations,
                  ),
                TripManagementButtons(
                  trip: trip,
                  controller: controller,
                  isLoading: state.isLoading,
                  cannotCancel: cannotCancel,
                  localizations: localizations,
                ),
              ] else ...[
                TripSenderSection(
                  tripId: trip.id,
                  userBooking: state.userBooking,
                  isLoading: state.isLoading,
                  hasActiveBooking: hasActiveBooking,
                  ratedBookingIds: state.ratedBookingIds,
                  trip: trip,
                  localizations: localizations,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TripHeroImage extends StatelessWidget {
  final Trip trip;

  const _TripHeroImage({required this.trip});

  @override
  Widget build(BuildContext context) {
    // Robust image selection:
    // Try to find an approved photo across all vehicles.
    String? imageUrl;
    final vehicles = trip.driver?.vehicles ?? [];

    for (final v in vehicles) {
      if (v.photoUrl != null && v.photoUrl!.trim().isNotEmpty) {
        imageUrl = v.photoUrl;
        break;
      }
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey[200],
          child: imageUrl != null && imageUrl.trim().isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, _, _) => const _TripHeroFallback(),
                )
              : const _TripHeroFallback(),
        ),
      ),
    );
  }
}

class _TripHeroFallback extends StatelessWidget {
  const _TripHeroFallback();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'لا توجد صورة للمركبة' : 'No vehicle photo available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
