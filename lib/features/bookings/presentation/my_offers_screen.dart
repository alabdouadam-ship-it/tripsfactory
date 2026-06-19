import 'package:tripship/core/config/app_constants.dart';
import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/features/offers/data/offer_providers.dart';
import 'package:tripship/features/offers/data/offer_service.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_status_badge.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';

class MyOffersScreen extends ConsumerStatefulWidget {
  const MyOffersScreen({super.key});

  @override
  ConsumerState<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends ConsumerState<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final offersAsync = ref.watch(myOffersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myOffers),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: loc.all),
            Tab(text: loc.statusPending),
            Tab(text: loc.statusAccepted),
            Tab(text: loc.statusCompleted),
            Tab(text: loc.statusRejected),
            Tab(text: loc.statusCancelled),
          ],
        ),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(getUserFriendlyMessage(e, loc.unexpectedError, context)),
        ),
        data: (allOffers) {
          final sent = allOffers
              .where((o) => o.status == OfferStatus.sent)
              .toList();
          final accepted = allOffers
              .where((o) => o.status == OfferStatus.accepted)
              .toList();
          final completed = allOffers
              .where((o) => o.status == OfferStatus.completed)
              .toList();
          final rejected = allOffers
              .where((o) => o.status == OfferStatus.rejected)
              .toList();
          final cancelled = allOffers
              .where((o) => o.status == OfferStatus.cancelled)
              .toList();

          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildOfferList(allOffers, loc, isArabic, loc.noOffersYet),
                  _buildOfferList(sent, loc, isArabic, loc.noOffersYet),
                  _buildOfferList(accepted, loc, isArabic, loc.noOffersYet),
                  _buildOfferList(completed, loc, isArabic, loc.noHistoryYet),
                  _buildOfferList(rejected, loc, isArabic, loc.noHistoryYet),
                  _buildOfferList(cancelled, loc, isArabic, loc.noHistoryYet),
                ],
              ),
              if (_isActionLoading)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfferList(
    List<Offer> offers,
    AppLocalizations loc,
    bool isArabic,
    String emptyText,
  ) {
    final theme = Theme.of(context);
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 56,
              color: theme.hintColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
      itemCount: offers.length,
      itemBuilder: (context, index) =>
          _buildOfferCard(offers[index], loc, isArabic),
    );
  }

  Widget _buildOfferCard(Offer offer, AppLocalizations loc, bool isArabic) {
    final theme = Theme.of(context);
    final shipment = offer.shipment;
    final senderName = shipment?.sender?.fullName ?? loc.sender;
    final senderAvatar = shipment?.sender?.avatarUrl;
    final senderRating =
        shipment?.sender?.clientRatingAvg?.toStringAsFixed(1) ?? '0.0';

    void openSenderProfile() {
      _openSenderProfile(offer, fallbackSenderName: senderName);
    }

    // Route info from shipment locations
    final pickupLoc = shipment?.pickupLocation;
    final dropoffLoc = shipment?.dropoffLocation;
    final isExternal = Location.isExternalTrip(pickupLoc, dropoffLoc);
    final pickup =
        pickupLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final dropoff =
        dropoffLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final route = (pickup.isNotEmpty && dropoff.isNotEmpty)
        ? '$pickup → $dropoff'
        : loc.shipment;

    final bgColor = isExternal
        ? const Color(0xFFFEE2E2).withValues(alpha: 0.3)
        : const Color(0xFFD1FAE5).withValues(alpha: 0.3);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.offerDetails, extra: offer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Route
              Text(
                route,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ── Sender profile row
              Row(
                children: [
                  GestureDetector(
                    onTap: openSenderProfile,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          (senderAvatar != null &&
                              senderAvatar.trim().isNotEmpty)
                          ? NetworkImage(senderAvatar)
                          : null,
                      child:
                          (senderAvatar == null || senderAvatar.trim().isEmpty)
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: openSenderProfile,
                          child: Text(
                            senderName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              senderRating,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      OfferStatusBadge(status: offer.status, compact: true),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            context.push(AppRoutes.offerDetails, extra: offer),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          loc.view,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(
                color: theme.dividerColor.withValues(alpha: 0.4),
                height: 1,
              ),
              const SizedBox(height: 10),

              // ── Price row
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    offer.price.toStringAsFixed(0),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Cancel button (sent only)
                  if (offer.status == OfferStatus.sent)
                    TextButton(
                      onPressed: () => _cancelOffer(offer.id),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(loc.cancel),
                    ),
                ],
              ),
              if (shipment?.description != null &&
                  shipment!.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  shipment.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    height: 1.3,
                  ),
                ),
              ],

              // ── Rejection reason
              if (offer.status == OfferStatus.rejected &&
                  offer.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offer.rejectionReason == 'other_offer_accepted'
                            ? loc.anotherOfferAccepted
                            : offer.rejectionReason!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSenderProfile(
    Offer offer, {
    required String fallbackSenderName,
  }) async {
    var senderId = offer.shipment?.sender?.id ?? offer.shipment?.senderId;
    var senderName = offer.shipment?.sender?.fullName ?? fallbackSenderName;

    if (senderId == null || senderId.isEmpty) {
      try {
        final shipment = await ref
            .read(shipmentServiceProvider)
            .getShipmentById(offer.shipmentId);
        senderId = shipment.sender?.id ?? shipment.senderId;
        senderName = shipment.sender?.fullName ?? senderName;
      } catch (_) {
        // If shipment lookup fails, we'll stop navigation below.
      }
    }

    if (!mounted || senderId == null || senderId.isEmpty) return;

    context.push(
      AppRoutes.travelerProfile,
      extra: {
        'driverId': senderId,
        'driverName': senderName,
        'role': AppConstants.roleClient,
      },
    );
  }

  Future<void> _cancelOffer(String offerId) async {
    try {
      setState(() => _isActionLoading = true);
      await ref.read(offerServiceProvider).cancelOffer(offerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.statusUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.unexpectedError,
                context,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}
