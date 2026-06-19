import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/safety/data/safety_service.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/widgets/delivery_code_card.dart';
import 'package:tripship/core/widgets/skeleton_loader.dart';
import 'package:tripship/core/widgets/tripship_dialog.dart';
import 'package:tripship/core/widgets/tripship_expandable_text.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/features/offers/data/offer_providers.dart';
import 'package:tripship/features/offers/data/offer_service.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_card.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_chat_widget.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/shipments/data/shipment_providers.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';
import 'package:tripship/features/shipments/presentation/widgets/shipment_otp_dialog.dart';
import 'package:tripship/features/shipments/presentation/widgets/shipment_progress_stepper.dart';
import 'package:tripship/features/ratings/data/rating_service.dart';
import 'package:tripship/features/ratings/presentation/rating_dialog.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class ShipmentDetailsScreen extends ConsumerStatefulWidget {
  final Shipment? shipment;
  final String? shipmentId;

  const ShipmentDetailsScreen({super.key, this.shipment, this.shipmentId});

  @override
  ConsumerState<ShipmentDetailsScreen> createState() =>
      _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends ConsumerState<ShipmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  Shipment? _shipment;
  bool _isActionLoading = false;
  bool _pastOffersExpanded = false;
  TabController? _tabController;
  Offer? _recentlySentOffer;
  final _offerPriceController = TextEditingController();
  final _offerMessageController = TextEditingController();
  final Set<String> _ratedOfferIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShipment();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _offerPriceController.dispose();
    _offerMessageController.dispose();
    super.dispose();
  }

  bool get _isOwner =>
      _shipment?.senderId == ref.read(authServiceProvider).currentUser?.id;

  Future<void> _showSendOfferDialog() async {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    _offerPriceController.clear();
    _offerMessageController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isArabic ? 'تقديم عرض' : 'Send Offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _offerPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'السعر' : 'Price',
                    hintText: isArabic ? 'مثال: 500' : 'e.g. 500',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _offerMessageController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'رسالة العرض' : 'Offer message',
                    hintText: isArabic
                        ? 'اكتب رسالتك الأولى لصاحب الشحنة'
                        : 'Write your first message to the sender',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isArabic ? 'إرسال العرض' : 'Send Offer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _shipment == null) return;

    final price = double.tryParse(_offerPriceController.text.trim());
    final message = _offerMessageController.text.trim();
    if (price == null || price <= 0 || message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'أدخل السعر والرسالة بشكل صحيح'
                : 'Please enter a valid price and message',
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isActionLoading = true);
      final offer = await ref
          .read(offerServiceProvider)
          .sendOffer(shipmentId: _shipment!.id, price: price, message: message);

      if (!mounted) return;
      setState(() {
        _recentlySentOffer = offer;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم إرسال العرض بنجاح' : 'Offer sent successfully',
          ),
        ),
      );

      context.push(AppRoutes.offerDetails, extra: offer);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getUserFriendlyMessage(e, loc.unexpectedError, context),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // ── Offer actions ──

  Future<void> _acceptOffer(Offer offer) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => TripShipDialog(
        title: loc.accept,
        content: Localizations.localeOf(context).languageCode == 'ar'
            ? 'هل أنت متأكد من قبول هذا العرض؟ سيتم رفض باقي العروض تلقائياً.'
            : 'Accept this offer? All other offers will be auto-rejected.',
        cancelLabel: loc.cancel,
        confirmLabel: loc.accept,
        icon: Icons.check_circle_outline,
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true) return;
    try {
      setState(() => _isActionLoading = true);
      await ref.read(offerServiceProvider).acceptOffer(offer.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.offerAccepted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, loc.unexpectedError, context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _rejectOffer(Offer offer) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => TripShipDialog(
        title: loc.reject,
        content: Localizations.localeOf(context).languageCode == 'ar'
            ? 'هل تريد رفض هذا العرض؟'
            : 'Reject this offer?',
        cancelLabel: loc.cancel,
        confirmLabel: loc.reject,
        isDestructive: true,
        icon: Icons.block_outlined,
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true) return;
    try {
      setState(() => _isActionLoading = true);
      await ref.read(offerServiceProvider).rejectOffer(offer.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, loc.unexpectedError, context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deleteShipment() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => TripShipDialog(
        title: loc.delete,
        content: loc.confirmCloseRequest,
        cancelLabel: loc.cancel,
        confirmLabel: loc.delete,
        isDestructive: true,
        icon: Icons.delete_outline,
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed == true && _shipment != null) {
      try {
        setState(() => _isActionLoading = true);
        await ref.read(shipmentServiceProvider).deleteShipment(_shipment!.id);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isActionLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getUserFriendlyMessage(e, loc.unexpectedError, context),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadShipment() async {
    // Rely on shipmentStreamProvider. No initial load needed here.
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final shipmentId = widget.shipmentId ?? widget.shipment?.id;

    if (shipmentId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.shipmentDetails),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
        body: Center(child: Text(loc.unknown)),
      );
    }

    final shipmentAsync = ref.watch(shipmentStreamProvider(shipmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.shipmentDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRoutes.home),
          ),
          if (_shipment != null && _isOwner) ...[
            if (_shipment!.status == ShipmentStatus.pending)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteShipment,
              ),
          ],
          if (_shipment != null && _isOwner && _tabController?.index == 1)
            _buildBlockReportMenu(context),
        ],
      ),
      body: shipmentAsync.when(
        data: (shipment) {
          // Store the current shipment in local state for action handlers
          _shipment = shipment;
          return _isOwner
              ? _buildOwnerView(context)
              : _buildDriverView(context);
        },
        loading: () {
          if (_shipment != null) {
            return _isOwner
                ? _buildOwnerView(context)
                : _buildDriverView(context);
          }
          return const ShipmentDetailsSkeleton();
        },
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(getUserFriendlyMessage(e, loc.unexpectedError, context)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(shipmentStreamProvider(shipmentId)),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // OWNER VIEW: Sticky header + 3 tabs
  // ══════════════════════════════════════════════════════

  Widget _buildOwnerView(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final offers = ref.watch(offersForShipmentProvider(_shipment!.id));
    final tabBottomPadding = _ownerTabBottomPadding(context);

    return Stack(
      children: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: _buildStickyHeader(loc, isArabic)),
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabHeaderDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: isArabic ? 'العروض' : 'Offers'),
                        Tab(text: isArabic ? 'المحادثة' : 'Chat'),
                        Tab(text: isArabic ? 'التحديثات' : 'Updates'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _tabController == null
              ? const SizedBox.shrink()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Offers
                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          key: const PageStorageKey('shipment_offers_tab'),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            SliverToBoxAdapter(
                              child: offers.when(
                                data: (list) {
                                  final acceptedOffer = list
                                      .where(
                                        (o) =>
                                            o.status == OfferStatus.accepted ||
                                            o.status == OfferStatus.completed,
                                      )
                                      .firstOrNull;
                                  return Column(
                                    children: [
                                      if (_shipment!.status !=
                                              ShipmentStatus.pending &&
                                          _shipment!.status !=
                                              ShipmentStatus.inCommunication &&
                                          _shipment!.status !=
                                              ShipmentStatus.cancelled)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          child: ShipmentProgressStepper(
                                            shipment: _shipment!,
                                          ),
                                        ),
                                      if (acceptedOffer != null)
                                        _buildOwnerTrackingActions(
                                          context,
                                          acceptedOffer,
                                        ),
                                      // We use a non-scrollable version of the offers tab list here
                                      // because it's already inside a CustomScrollView's SliverToBoxAdapter.
                                      _buildOffersTab(
                                        list,
                                        loc,
                                        isArabic,
                                        shrinkWrap: true,
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (e, _) => Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(loc.unexpectedError),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom: tabBottomPadding,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Tab 2: Chat
                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          key: const PageStorageKey('shipment_chat_tab'),
                          physics: const NeverScrollableScrollPhysics(),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            SliverFillRemaining(
                              child: offers.when(
                                data: (list) => _buildChatTab(list, isArabic),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (err, stack) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Tab 3: Updates
                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          key: const PageStorageKey('shipment_updates_tab'),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            SliverToBoxAdapter(
                              child: offers.when(
                                data: (list) => _buildUpdatesTab(
                                  list,
                                  isArabic,
                                  shrinkWrap: true,
                                ),
                                loading: () => const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (err, stack) => const SizedBox.shrink(),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom: tabBottomPadding,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
        ),
        if (_isActionLoading)
          const ColoredBox(
            color: Colors.black26,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildOwnerTrackingActions(BuildContext context, Offer acceptedOffer) {
    if (_shipment == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = AppLocalizations.of(context)!;
    final s = _shipment!;
    final List<Widget> actions = [];

    // OTP Delivery Code card (shown until client confirms receipt).
    // The code comes from the sender-only delivery_codes table.
    if (s.goodsReceivedByClientAt == null) {
      actions.add(
        DeliveryCodeCard(
          shipmentId: s.id,
          title: loc.shipmentDeliveryCode,
          hint: loc.shipmentShareCodeHint,
          copiedLabel: loc.shipmentDeliveryCodeCopied,
        ),
      );
    }

    if (s.canClientConfirmDelivery) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                _handleTrackingAction('confirmGoodsReceivedByClient'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(loc.shipmentConfirmReceived),
          ),
        ),
      );
    }

    if (!s.isCollected && s.goodsHandedBySenderAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleTrackingAction('markGoodsHandedOver'),
            child: Text(loc.shipmentHandedToDriver),
          ),
        ),
      );
    }

    // Payment Sent button (sender marks payment)
    if (s.status != ShipmentStatus.completed &&
        s.isCollected &&
        !s.isPaid &&
        s.paymentMarkedBySenderAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleTrackingAction('markPaymentSent'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(loc.shipmentPaymentSentToDriver),
          ),
        ),
      );
    }

    // Indicators
    if (s.goodsReceivedByDriverAt != null) {
      actions.add(
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              loc.shipmentDriverReceivedGoods,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (s.paymentConfirmedByDriverAt != null) {
      actions.add(
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              loc.shipmentDriverConfirmedPayment,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (acceptedOffer.status == OfferStatus.completed) {
      final hasRatedLocally = _ratedOfferIds.contains(acceptedOffer.id);

      actions.add(
        FutureBuilder<bool>(
          future: hasRatedLocally
              ? Future.value(true)
              : ref
                    .read(ratingServiceProvider)
                    .hasRatedForOffer(acceptedOffer.id),
          builder: (context, snapshot) {
            final hasRatedDb = snapshot.data ?? false;
            final isRated = hasRatedLocally || hasRatedDb;

            if (!isRated) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _rateDriver(context, acceptedOffer),
                  icon: const Icon(Icons.star, size: 24),
                  label: Text(
                    isArabic ? 'تقييم السائق' : 'Rate Driver',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isArabic ? '✅ شكرًا لتقييمك!' : '✅ Thank you for rating!',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
          },
        ),
      );
    }

    // Cancel button (before goods received)
    if (s.status == ShipmentStatus.accepted &&
        s.goodsReceivedByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final loc = AppLocalizations.of(context)!;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => TripShipDialog(
                  title: loc.cancel,
                  content: isArabic
                      ? 'هل تريد إلغاء هذه الشحنة؟'
                      : 'Cancel this shipment engagement?',
                  cancelLabel: loc.cancel,
                  confirmLabel: isArabic ? 'نعم، إلغاء' : 'Yes, Cancel',
                  isDestructive: true,
                  icon: Icons.cancel_outlined,
                  onCancel: () => Navigator.pop(ctx, false),
                  onConfirm: () => Navigator.pop(ctx, true),
                ),
              );
              if (confirmed == true && mounted) {
                try {
                  setState(() => _isActionLoading = true);
                  await ref
                      .read(shipmentServiceProvider)
                      .cancelShipment(_shipment!.id);
                } catch (e) {
                  if (!context.mounted) return;
                  final loc = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getUserFriendlyMessage(e, loc.unexpectedError, context),
                      ),
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: Text(isArabic ? 'إلغاء الشحنة' : 'Cancel Shipment'),
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            actions[i],
          ],
        ],
      ),
    );
  }

  void _rateDriver(BuildContext context, Offer offer) async {
    final driverId = offer.driverId;
    if (driverId.isEmpty || !mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratedUserId: driverId,
        ratedUserRole: 'driver',
        offerId: offer.id,
      ),
    );
    if (result == true) {
      if (mounted) setState(() => _ratedOfferIds.add(offer.id));
    }
  }

  double _ownerTabBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  Widget _buildStickyHeader(AppLocalizations loc, bool isArabic) {
    final theme = Theme.of(context);
    final shipment = _shipment!;
    final pickupLoc = shipment.pickupLocation;
    final dropoffLoc = shipment.dropoffLocation;
    final isExternal = Location.isExternalTrip(pickupLoc, dropoffLoc);
    final pickupLabel =
        pickupLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final dropoffLabel =
        dropoffLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final date = shipment.pickupDate ?? shipment.createdAt;

    final isDarkMode = theme.brightness == Brightness.dark;
    final cardBgColor = isExternal
        ? (isDarkMode
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFFFFEBEE))
        : (isDarkMode
              ? Colors.green.withValues(alpha: 0.1)
              : const Color(0xFFE8F5E9));

    final borderColor = isExternal
        ? Colors.red.withValues(alpha: 0.3)
        : Colors.green.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationRow(
                      context,
                      Icons.trip_origin,
                      pickupLabel,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildLocationRow(
                      context,
                      Icons.location_on,
                      dropoffLabel,
                      Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(context, shipment.status),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 10),

          if (shipment.description != null &&
              shipment.description!.isNotEmpty) ...[
            TripShipExpandableText(
              text: shipment.description!,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat.MMMd().format(date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (shipment.weightKg > 0) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.scale_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${shipment.weightKg.toStringAsFixed(0)} kg',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),
              _buildTransportBadge(context, isExternal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    IconData icon,
    String location,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportBadge(BuildContext context, bool isExternal) {
    final localizations = AppLocalizations.of(context)!;
    final color = isExternal ? Colors.red : Colors.green;
    final label = isExternal
        ? localizations.externalShipping
        : localizations.internalShipping;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ShipmentStatus status) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final (Color color, String label) = switch (status) {
      ShipmentStatus.pending => (
        Colors.orange,
        isArabic ? 'بانتظار' : 'Pending',
      ),
      ShipmentStatus.inCommunication => (
        Colors.blue,
        isArabic ? 'تواصل' : 'In Communication',
      ),
      ShipmentStatus.accepted => (
        const Color(0xFF059669),
        isArabic ? 'مقبول' : 'Accepted',
      ),
      ShipmentStatus.pickedUp => (
        Colors.purple,
        isArabic ? 'تم الاستلام' : 'Picked Up',
      ),
      ShipmentStatus.inTransit => (
        Colors.deepPurple,
        isArabic ? 'قيد التنفيذ' : 'In Transit',
      ),
      ShipmentStatus.delivered => (
        Colors.teal,
        isArabic ? 'تم التسليم' : 'Delivered',
      ),
      ShipmentStatus.completed => (
        Colors.green,
        isArabic ? 'مكتملة' : 'Completed',
      ),
      ShipmentStatus.cancelled => (
        Colors.grey,
        isArabic ? 'ملغاة' : 'Cancelled',
      ),
      ShipmentStatus.expired => (
        Colors.grey,
        isArabic ? 'منتهية الصلاحية' : 'Expired',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Offers ──

  Widget _buildOffersTab(
    List<Offer> offers,
    AppLocalizations loc,
    bool isArabic, {
    bool shrinkWrap = false,
  }) {
    final accepted = offers
        .where(
          (o) =>
              o.status == OfferStatus.accepted ||
              o.status == OfferStatus.completed,
        )
        .toList();

    final canAcceptOptions =
        _shipment?.status == ShipmentStatus.pending ||
        _shipment?.status == ShipmentStatus.inCommunication;

    final pending = canAcceptOptions
        ? offers.where((o) => o.status == OfferStatus.sent).toList()
        : <Offer>[];
    final past = offers
        .where(
          (o) =>
              o.status == OfferStatus.rejected ||
              o.status == OfferStatus.cancelled ||
              (!canAcceptOptions && o.status == OfferStatus.sent),
        )
        .toList();

    if (accepted.isEmpty && pending.isEmpty && past.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                canAcceptOptions
                    ? (isArabic
                          ? 'لا توجد عروض بعد — سيقوم السائقون بإرسال عروضهم هنا'
                          : 'No offers yet — drivers will send their offers here')
                    : (isArabic
                          ? 'لا توجد عروض متاحة لعرضها.'
                          : 'No offers available to display.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        // Section 1: Accepted
        if (accepted.isNotEmpty) ...[
          _sectionTitle(
            isArabic ? 'العرض المقبول' : 'Accepted Offer',
            Icons.check_circle,
            const Color(0xFF059669),
          ),
          const SizedBox(height: 8),
          for (final o in accepted)
            OfferCard(
              offer: o,
              isPinned: true,
              onChat: () {
                _tabController?.animateTo(1);
                ref.read(selectedOfferIdProvider.notifier).state = o.id;
              },
            ),
        ],
        // Section 2: Pending
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle(
            isArabic ? 'عروض بانتظار قرار' : 'Offers Awaiting Decision',
            Icons.hourglass_top_outlined,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          for (final o in pending)
            OfferCard(
              offer: o,
              onAccept:
                  (_shipment?.status == ShipmentStatus.pending ||
                      _shipment?.status == ShipmentStatus.inCommunication)
                  ? () => _acceptOffer(o)
                  : null,
              onReject:
                  (_shipment?.status == ShipmentStatus.pending ||
                      _shipment?.status == ShipmentStatus.inCommunication)
                  ? () => _rejectOffer(o)
                  : null,
              onChat: () {
                _tabController?.animateTo(1);
                ref.read(selectedOfferIdProvider.notifier).state = o.id;
              },
            ),
        ],
        // Section 3: Past (collapsible)
        if (past.isNotEmpty) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () =>
                setState(() => _pastOffersExpanded = !_pastOffersExpanded),
            child: Row(
              children: [
                Icon(
                  _pastOffersExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isArabic ? "العروض السابقة" : "Past Offers"} (${past.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_pastOffersExpanded) ...[
            const SizedBox(height: 8),
            for (final o in past) OfferCard(offer: o),
          ],
        ],
      ],
    );
  }

  // ── Tracking Actions Handler ──

  Future<void> _handleTrackingAction(String action) async {
    if (_shipment == null) return;
    try {
      setState(() => _isActionLoading = true);
      final service = ref.read(shipmentServiceProvider);
      switch (action) {
        case 'markGoodsHandedOver':
          await service.markGoodsHandedOver(_shipment!.id);
          break;
        case 'confirmGoodsReceived':
          await service.confirmGoodsReceived(_shipment!.id);
          break;
        case 'markPaymentSent':
          await service.markPaymentSent(_shipment!.id);
          break;
        case 'confirmPaymentReceived':
          await service.confirmPaymentReceived(_shipment!.id);
          break;
        case 'markGoodsDelivered':
          await service.markGoodsDelivered(_shipment!.id);
          break;
        case 'confirmGoodsReceivedByClient':
          await service.confirmGoodsReceivedByClient(_shipment!.id);
          break;
      }
      // Optimistic manual refresh
      final shipmentId = _shipment?.id;
      if (shipmentId != null) {
        ref.invalidate(shipmentStreamProvider(shipmentId));
        ref.invalidate(offersForShipmentProvider(shipmentId));
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, loc.unexpectedError, context),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // ── Tab 2: Chat ──

  Widget _buildChatTab(List<Offer> offers, bool isArabic) {
    final theme = Theme.of(context);
    final activeOffers = offers
        .where(
          (o) =>
              o.status == OfferStatus.sent ||
              o.status == OfferStatus.accepted ||
              o.status == OfferStatus.completed,
        )
        .toList();
    final selectedId = ref.watch(selectedOfferIdProvider);

    // Default selection
    final acceptedOffer = offers
        .where(
          (o) =>
              o.status == OfferStatus.accepted ||
              o.status == OfferStatus.completed,
        )
        .toList();
    final effectiveId =
        selectedId ??
        (acceptedOffer.isNotEmpty
            ? acceptedOffer.first.id
            : (activeOffers.isNotEmpty ? activeOffers.first.id : null));
    final selectedOffer = effectiveId != null
        ? offers.where((o) => o.id == effectiveId).toList()
        : <Offer>[];

    if (offers.isEmpty || effectiveId == null) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد محادثات متاحة' : 'No chats available',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    final currentOffer = selectedOffer.isNotEmpty
        ? selectedOffer.first
        : offers.first;

    return Column(
      children: [
        // Offer picker (if multiple active)
        if (activeOffers.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: effectiveId,
              decoration: InputDecoration(
                labelText: isArabic ? 'اختر العرض' : 'Select offer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: activeOffers
                  .map(
                    (o) => DropdownMenuItem(
                      value: o.id,
                      child: Text(
                        '${o.driver?.fullName ?? "Driver"} — ${o.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  ref.read(selectedOfferIdProvider.notifier).state = v,
            ),
          ),

        // Chat widget
        Expanded(
          child: OfferChatWidget(
            offerId: currentOffer.id,
            offerStatus: currentOffer.status,
            otherUserId: currentOffer.driverId,
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Updates/Timeline ──

  Widget _buildUpdatesTab(
    List<Offer> offers,
    bool isArabic, {
    bool shrinkWrap = false,
  }) {
    final theme = Theme.of(context);
    final events = <_TimelineEvent>[];

    // Determine the accepted driver's name (if any)
    final acceptedOffer = offers
        .where(
          (o) =>
              o.status == OfferStatus.accepted ||
              o.status == OfferStatus.completed,
        )
        .firstOrNull;
    final acceptedDriverName =
        acceptedOffer?.driver?.fullName ?? (isArabic ? 'السائق' : 'Driver');
    final senderName =
        _shipment?.sender?.fullName ?? (isArabic ? 'المرسل' : 'Sender');

    // 1. Shipment Creating Events
    if (_shipment != null) {
      events.add(
        _TimelineEvent(
          time: _shipment!.createdAt,
          icon: Icons.add_box_outlined,
          color: Colors.blueGrey,
          text: isArabic
              ? 'نشر $senderName الشحنة'
              : '$senderName posted the shipment',
        ),
      );
    }

    for (final o in offers) {
      final driverName = o.driver?.fullName ?? (isArabic ? 'سائق' : 'Driver');
      events.add(
        _TimelineEvent(
          time: o.createdAt,
          icon: Icons.local_offer_outlined,
          color: Colors.blue,
          text: isArabic
              ? 'عرض جديد من $driverName'
              : 'New offer from $driverName',
        ),
      );
      if (o.status == OfferStatus.accepted ||
          o.status == OfferStatus.completed) {
        events.add(
          _TimelineEvent(
            time: o.updatedAt ?? o.createdAt,
            icon: Icons.check_circle,
            color: const Color(0xFF059669),
            text: isArabic
                ? 'تم قبول عرض $driverName'
                : 'Accepted offer from $driverName',
          ),
        );
      }
      if (o.status == OfferStatus.rejected) {
        events.add(
          _TimelineEvent(
            time: o.updatedAt ?? o.createdAt,
            icon: Icons.cancel,
            color: Colors.red,
            text: o.rejectionReason == 'other_offer_accepted'
                ? (isArabic
                      ? 'تم رفض عرض $driverName تلقائياً'
                      : 'Auto-rejected $driverName')
                : (isArabic
                      ? 'تم رفض عرض $driverName'
                      : 'Rejected $driverName'),
          ),
        );
      }
      if (o.status == OfferStatus.cancelled) {
        events.add(
          _TimelineEvent(
            time: o.updatedAt ?? o.createdAt,
            icon: Icons.remove_circle_outline,
            color: Colors.grey,
            text: isArabic
                ? 'قام $driverName بإلغاء عرضه'
                : '$driverName cancelled their offer',
          ),
        );
      }
    }

    // ── 2. Shipment Tracking Events ──
    if (_shipment != null) {
      if (_shipment!.goodsHandedBySenderAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.goodsHandedBySenderAt!,
            icon: Icons.outbox,
            color: Colors.teal,
            text: isArabic
                ? 'سلّم $senderName الشحنة'
                : '$senderName handed over the shipment',
          ),
        );
      }
      if (_shipment!.goodsReceivedByDriverAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.goodsReceivedByDriverAt!,
            icon: Icons.inbox,
            color: Colors.teal,
            text: isArabic
                ? 'استلم $acceptedDriverName الشحنة'
                : '$acceptedDriverName received the shipment',
          ),
        );
      }
      if (_shipment!.paymentMarkedBySenderAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.paymentMarkedBySenderAt!,
            icon: Icons.payment,
            color: Colors.purple,
            text: isArabic
                ? 'دفع $senderName لـ $acceptedDriverName'
                : '$senderName paid $acceptedDriverName',
          ),
        );
      }
      if (_shipment!.paymentConfirmedByDriverAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.paymentConfirmedByDriverAt!,
            icon: Icons.account_balance_wallet,
            color: Colors.purple,
            text: isArabic
                ? 'استلم $acceptedDriverName المبلغ من $senderName'
                : '$acceptedDriverName received the payment from $senderName',
          ),
        );
      }
      if (_shipment!.goodsDeliveredByDriverAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.goodsDeliveredByDriverAt!,
            icon: Icons.location_on,
            color: Colors.orange,
            text: isArabic
                ? 'أوصل $acceptedDriverName الشحنة'
                : '$acceptedDriverName delivered the shipment',
          ),
        );
      }
      if (_shipment!.goodsReceivedByClientAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.goodsReceivedByClientAt!,
            icon: Icons.verified,
            color: const Color(0xFF059669),
            text: isArabic
                ? 'أكد $senderName وصول الشحنة من $acceptedDriverName'
                : '$senderName confirmed delivery from $acceptedDriverName',
          ),
        );
      }
      if (_shipment!.status == ShipmentStatus.delivered &&
          _shipment!.goodsReceivedByClientAt != null) {
        events.add(
          _TimelineEvent(
            time: _shipment!.goodsReceivedByClientAt!.add(
              const Duration(minutes: 1),
            ),
            icon: Icons.flag,
            color: const Color(0xFF059669),
            text: isArabic
                ? 'تم إكمال الشحنة مع $acceptedDriverName بنجاح'
                : 'Shipment successfully completed with $acceptedDriverName',
          ),
        );
      }
      if (_shipment!.status == ShipmentStatus.cancelled) {
        events.add(
          _TimelineEvent(
            time: _shipment!.createdAt,
            icon: Icons.block,
            color: Colors.red,
            text: isArabic ? 'تم إلغاء الشحنة' : 'Shipment cancelled',
          ),
        );
      }
    }

    events.sort((a, b) => b.time.compareTo(a.time));

    if (events.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد تحديثات بعد' : 'No updates yet',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final ev = events[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ev.icon, size: 20, color: ev.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ev.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(ev.time.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // DRIVER VIEW: Simple scroll (shipment info + sender)
  // ══════════════════════════════════════════════════════

  Widget _buildDriverView(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final shipment = _shipment!;
    final myOffersAsync = ref.watch(myOffersStreamProvider);
    final cachedOffer = _recentlySentOffer?.shipmentId == shipment.id
        ? _recentlySentOffer
        : null;

    Widget buildOpenMessagesCta(Offer offer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'تم إرسال عرضك لهذه الشحنة'
                  : 'You already sent an offer for this shipment',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.offerDetails, extra: offer),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(isArabic ? 'رؤية العرض' : 'View Offer'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStickyHeader(loc, isArabic),
              const SizedBox(height: 16),

              // ── Tracking Stepper (if accepted or beyond)
              if (_shipment!.status != ShipmentStatus.pending &&
                  _shipment!.status != ShipmentStatus.inCommunication &&
                  _shipment!.status != ShipmentStatus.cancelled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShipmentProgressStepper(shipment: _shipment!),
                ),

              // Sender
              Text(loc.sender, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  if (shipment.senderId.isNotEmpty) {
                    context.push(
                      '/traveler-profile',
                      extra: {
                        'driverId': shipment.senderId,
                        'driverName': shipment.sender?.fullName ?? loc.unknown,
                        'role': 'client',
                      },
                    );
                  }
                },
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      (shipment.sender?.avatarUrl != null &&
                          shipment.sender!.avatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(shipment.sender!.avatarUrl!)
                      : null,
                  child:
                      (shipment.sender?.avatarUrl == null ||
                          shipment.sender!.avatarUrl!.trim().isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  shipment.sender?.fullName ?? loc.unknown,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const Divider(height: 32),

              // Offer / chat action section for driver
              myOffersAsync.when(
                data: (myOffers) {
                  Offer? myOfferForShipment = cachedOffer;
                  if (myOfferForShipment == null) {
                    for (final o in myOffers) {
                      if (o.shipmentId == shipment.id) {
                        myOfferForShipment = o;
                        break;
                      }
                    }
                  }

                  if (myOfferForShipment != null) {
                    return buildOpenMessagesCta(myOfferForShipment);
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showSendOfferDialog,
                      icon: const Icon(Icons.local_offer_outlined),
                      label: Text(isArabic ? 'تقديم عرض' : 'Send Offer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                },
                loading: () => cachedOffer != null
                    ? buildOpenMessagesCta(cachedOffer)
                    : const Center(child: CircularProgressIndicator()),
                error: (err, stack) => cachedOffer != null
                    ? buildOpenMessagesCta(cachedOffer)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showSendOfferDialog,
                          icon: const Icon(Icons.local_offer_outlined),
                          label: Text(isArabic ? 'تقديم عرض' : 'Send Offer'),
                        ),
                      ),
              ),

              // Tracking Actions
              myOffersAsync.whenData((offers) {
                    final myOfferForShipment =
                        offers
                            .where((o) => o.shipmentId == shipment.id)
                            .firstOrNull ??
                        cachedOffer;
                    if (myOfferForShipment != null &&
                        (myOfferForShipment.status == OfferStatus.accepted ||
                            myOfferForShipment.status ==
                                OfferStatus.completed)) {
                      return _buildDriverTrackingActions(
                        context,
                        myOfferForShipment,
                      );
                    }
                    return const SizedBox.shrink();
                  }).value ??
                  const SizedBox.shrink(),
            ],
          ),
        ),
        if (_isActionLoading)
          const ColoredBox(
            color: Colors.black26,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _showDeliveryDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const ShipmentOtpDialog(),
    );

    if (result == 'no_code') {
      _handleTrackingAction('markGoodsDelivered');
    } else if (result != null && result.isNotEmpty) {
      _handleTrackingActionWithCode('markGoodsDeliveredWithCode', result);
    }
  }

  Future<void> _handleTrackingActionWithCode(String action, String code) async {
    if (_shipment == null) return;
    try {
      setState(() => _isActionLoading = true);
      final service = ref.read(shipmentServiceProvider);
      if (action == 'markGoodsDeliveredWithCode') {
        await service.markGoodsDeliveredWithCode(_shipment!.id, code);
      }
      // Optimistic manual refresh
      final shipmentId = _shipment?.id;
      if (shipmentId != null) {
        ref.invalidate(shipmentStreamProvider(shipmentId));
        ref.invalidate(offersForShipmentProvider(shipmentId));
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, loc.unexpectedError, context),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Widget _buildDriverTrackingActions(BuildContext context, Offer offer) {
    if (_shipment == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final s = _shipment!;
    final List<Widget> actions = [];

    if (s.isWaitingForClientDeliveryConfirm) {
      actions.add(
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            isArabic
                ? 'بانتظار تأكيد العميل لاستلام الشحنة'
                : 'Waiting for client to confirm delivery',
            style: TextStyle(
              color: Colors.orange[800],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Driver can always just say "Received" even if sender didn't mark "Handed"
    if (!s.isCollected && s.goodsReceivedByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleTrackingAction('confirmGoodsReceived'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              isArabic ? 'تأكيد استلام الشحنة' : 'Confirm Shipment Received',
            ),
          ),
        ),
      );
    }

    // Delivery Action
    if (s.isCollected && !s.isDelivered && s.goodsDeliveredByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showDeliveryDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isArabic ? 'سلمت الشحنة' : 'Mark as Delivered',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      );
    }

    // Driver can confirm payment even if sender didn't formally "Mark Payment Sent"
    if (s.status != ShipmentStatus.completed &&
        s.isCollected &&
        !s.isPaid &&
        s.paymentConfirmedByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleTrackingAction('confirmPaymentReceived'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              isArabic ? 'تأكيد استلام الدفعة' : 'Confirm Payment Received',
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            actions[i],
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockReportMenu(BuildContext context) {
    if (_shipment == null) return const SizedBox.shrink();
    final selectedId = ref.watch(selectedOfferIdProvider);
    final offersAsync = ref.watch(offersForShipmentProvider(_shipment!.id));

    return offersAsync.when(
      data: (offers) {
        final activeOffers = offers
            .where(
              (o) =>
                  o.status == OfferStatus.sent ||
                  o.status == OfferStatus.accepted ||
                  o.status == OfferStatus.completed,
            )
            .toList();

        final acceptedOffer = offers
            .where(
              (o) =>
                  o.status == OfferStatus.accepted ||
                  o.status == OfferStatus.completed,
            )
            .toList();
        final effectiveId =
            selectedId ??
            (acceptedOffer.isNotEmpty
                ? acceptedOffer.first.id
                : (activeOffers.isNotEmpty ? activeOffers.first.id : null));

        final selectedOffer = effectiveId != null
            ? offers.where((o) => o.id == effectiveId).firstOrNull
            : null;

        final targetId = selectedOffer?.driverId ?? selectedOffer?.driver?.id;
        if (targetId == null) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'report') {
              _showReportDialog(context, targetId);
            } else if (value == 'block') {
              _showBlockDialog(context, targetId);
            }
          },
          itemBuilder: (context) {
            final loc = AppLocalizations.of(context)!;
            return [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(loc.reportUser),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(loc.blockUser),
                  ],
                ),
              ),
            ];
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showReportDialog(BuildContext context, String userId) async {
    final loc = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.reportUser),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.reportUserDescription),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: loc.reportReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);

              try {
                setState(() => _isActionLoading = true);
                final result = await ref
                    .read(safetyServiceProvider)
                    .reportUser(
                      reportedId: userId,
                      reason: reason,
                      comment: 'Negotiation phase - Shipment: ${_shipment?.id}',
                      targetType: 'shipment',
                      targetShipmentId: _shipment?.id,
                    );
                if (context.mounted) {
                  final message = result == ReportResult.reportedAndBlocked
                      ? loc.reportSubmittedBlocked
                      : loc.reportSubmittedCannotBlock;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getUserFriendlyMessage(e, loc.unexpectedError, context),
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isActionLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.send),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  void _showBlockDialog(BuildContext context, String userId) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.blockUser),
        content: Text(loc.blockUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                setState(() => _isActionLoading = true);
                await ref.read(safetyServiceProvider).blockUser(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(
                    content: Text(loc.userBlockedSuccess),
                    backgroundColor: Colors.green,
                  ));
                  context.pop(); // Go back from details as user is now blocked
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getUserFriendlyMessage(e, loc.unexpectedError, context),
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isActionLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.blockUser),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final DateTime time;
  final IconData icon;
  final Color color;
  final String text;
  const _TimelineEvent({
    required this.time,
    required this.icon,
    required this.color,
    required this.text,
  });
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabHeaderDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) {
    return false;
  }
}
