import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/widgets/tripship_dialog.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/features/offers/data/offer_providers.dart';
import 'package:tripship/features/offers/data/offer_service.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_shipment_card.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_status_zone.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_chat_widget.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';
import 'package:tripship/features/safety/data/safety_service.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/shipments/data/shipment_providers.dart';
import 'package:tripship/features/shipments/presentation/widgets/shipment_otp_dialog.dart';
import 'package:tripship/features/shipments/presentation/widgets/shipment_progress_stepper.dart';
import 'package:tripship/features/ratings/data/rating_service.dart';
import 'package:tripship/features/ratings/presentation/rating_dialog.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// Traveler/Driver's view of a single offer — redesigned with:
/// 1. Compact shipment card (route + sender avatar on right, tappable)
/// 2. Offer status & actions zone
/// 3. Tabbed bottom panel (Chat + Timeline)
class OfferDetailsScreen extends ConsumerStatefulWidget {
  final Offer? offer;
  final String? offerId;

  const OfferDetailsScreen({super.key, this.offer, this.offerId});

  @override
  ConsumerState<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends ConsumerState<OfferDetailsScreen>
    with SingleTickerProviderStateMixin {
  Offer? _offer;
  bool _hasRated = false;
  bool _isActionLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfRated();
    });
  }

  Future<void> _checkIfRated() async {
    final offerId = widget.offerId ?? widget.offer?.id;
    if (offerId == null) return;
    try {
      final hasRated = await ref
          .read(ratingServiceProvider)
          .hasRatedForOffer(offerId);
      if (mounted) setState(() => _hasRated = hasRated);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openSenderProfile() async {
    final offer = _offer;
    if (offer == null) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    var senderId = offer.shipment?.sender?.id ?? offer.shipment?.senderId;
    var senderName =
        offer.shipment?.sender?.fullName ?? (isArabic ? 'مرسل' : 'Sender');

    if (senderId == null || senderId.isEmpty) {
      try {
        final shipment = await ref
            .read(shipmentServiceProvider)
            .getShipmentById(offer.shipmentId);
        senderId = shipment.sender?.id ?? shipment.senderId;
        senderName = shipment.sender?.fullName ?? senderName;
      } catch (_) {}
    }

    if (!mounted || senderId == null || senderId.isEmpty) return;

    context.push(
      '/traveler-profile',
      extra: {'driverId': senderId, 'driverName': senderName, 'role': 'client'},
    );
  }

  Future<void> _cancelOffer() async {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => TripShipDialog(
        title: isArabic ? 'إلغاء العرض' : 'Cancel Offer',
        content: isArabic ? 'هل تريد إلغاء عرضك؟' : 'Cancel your offer?',
        cancelLabel: loc.cancel,
        confirmLabel: isArabic ? 'إلغاء العرض' : 'Cancel Offer',
        isDestructive: true,
        icon: Icons.cancel_outlined,
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true || _offer == null) return;

    try {
      setState(() => _isActionLoading = true);
      await ref.read(offerServiceProvider).cancelOffer(_offer!.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.statusUpdated)));
        context.pop();
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

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final offerId = widget.offerId ?? widget.offer?.id;

    if (offerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'تفاصيل العرض' : 'Offer Details'),
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

    final offerAsync = ref.watch(offerStreamProvider(offerId));

    return offerAsync.when(
      data: (offer) {
        _offer = offer;
        return Scaffold(
          appBar: AppBar(
            title: Text(isArabic ? 'تفاصيل العرض' : 'Offer Details'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(AppRoutes.home),
              ),
              _buildBlockReportMenu(context),
            ],
          ),
          body: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: OfferShipmentCard(
                        offer: _offer!,
                        onSenderTap: _openSenderProfile,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        child: _buildTabBar(theme, isArabic),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: OfferStatusZone(
                        offer: _offer!,
                        isActionLoading: _isActionLoading,
                        onCancelOffer: _cancelOffer,
                        trackingSection:
                            _offer!.status == OfferStatus.accepted ||
                                _offer!.status == OfferStatus.completed
                            ? _buildTrackingSection(context, _offer!)
                            : null,
                      ),
                    ),
                    OfferChatWidget(
                      offerId: _offer!.id,
                      offerStatus: _offer!.status,
                      otherUserId:
                          _offer!.shipment?.sender?.id ??
                          _offer!.shipment?.senderId ??
                          '',
                    ),
                    _buildTimeline(theme, isArabic),
                  ],
                ),
              ),
              if (_isActionLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () {
        if (_offer != null) {
          // Keep showing the old state while loading new one
          return Scaffold(
            appBar: AppBar(
              title: Text(isArabic ? 'تفاصيل العرض' : 'Offer Details'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => context.go(AppRoutes.home),
                ),
                _buildBlockReportMenu(context),
              ],
            ),
            body: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: OfferShipmentCard(
                          offer: _offer!,
                          onSenderTap: _openSenderProfile,
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          child: _buildTabBar(theme, isArabic),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: OfferStatusZone(
                          offer: _offer!,
                          isActionLoading: _isActionLoading,
                          onCancelOffer: _cancelOffer,
                          trackingSection:
                              _offer!.status == OfferStatus.accepted ||
                                  _offer!.status == OfferStatus.completed
                              ? _buildTrackingSection(context, _offer!)
                              : null,
                        ),
                      ),
                      OfferChatWidget(
                        offerId: _offer!.id,
                        offerStatus: _offer!.status,
                        otherUserId:
                            _offer!.shipment?.sender?.id ??
                            _offer!.shipment?.senderId ??
                            '',
                      ),
                      _buildTimeline(theme, isArabic),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(isArabic ? 'تفاصيل العرض' : 'Offer Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'تفاصيل العرض' : 'Offer Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(getUserFriendlyMessage(e, loc.unexpectedError, context)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(offerStreamProvider(offerId)),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TRACKING SECTION
  // ─────────────────────────────────────────────────────────

  Widget _buildTrackingSection(BuildContext context, Offer offer) {
    final shipmentAsync = ref.watch(shipmentStreamProvider(offer.shipmentId));

    return shipmentAsync.when(
      data: (shipment) {
        return Column(
          children: [
            const Divider(height: 32),
            ShipmentProgressStepper(shipment: shipment),
            const SizedBox(height: 16),
            _buildDriverTrackingActions(context, shipment),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDriverTrackingActions(BuildContext context, Shipment s) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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

    if (!s.isCollected && s.goodsReceivedByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isActionLoading
                ? null
                : () => _handleTrackingAction(s.id, 'confirmGoodsReceived'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              isArabic ? 'تأكيد استلام الشحنة' : 'Confirm Shipment Received',
            ),
          ),
        ),
      );
    }

    if (s.isCollected && !s.isDelivered && s.goodsDeliveredByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isActionLoading
                ? null
                : () => _showDeliveryDialog(context, s.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isArabic ? 'سلمت الشحنة للوجهة' : 'Mark Shipment as Delivered',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (s.isCollected && !s.isPaid && s.paymentConfirmedByDriverAt == null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isActionLoading
                ? null
                : () => _handleTrackingAction(s.id, 'confirmPaymentReceived'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              isArabic ? 'تأكيد استلام الدفعة' : 'Confirm Payment Received',
            ),
          ),
        ),
      );
    }

    if (_offer != null && _offer!.status == OfferStatus.completed) {
      if (!_hasRated) {
        actions.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _rateSender(context, _offer!),
              icon: const Icon(Icons.star, size: 24),
              label: Text(
                isArabic ? 'تقييم تجربتك' : 'Rate Your Experience',
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
          ),
        );
      } else {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                isArabic ? '✅ شكرًا لتقييمك!' : '✅ Thank you for rating!',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

  void _rateSender(BuildContext context, Offer offer) async {
    final s = offer.shipment;
    if (s == null) return;

    // Fallback to searching the shipment for the sender manually if not attached to the offer model.
    var senderId = s.sender?.id ?? s.senderId;

    if (senderId.isEmpty) {
      try {
        final fetchedShipment = await ref
            .read(shipmentServiceProvider)
            .getShipmentById(offer.shipmentId);
        senderId = fetchedShipment.sender?.id ?? fetchedShipment.senderId;
      } catch (_) {}
    }

    if (senderId.isEmpty || !context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratedUserId: senderId,
        ratedUserRole: 'client',
        offerId: offer.id,
      ),
    );
    if (result == true) {
      if (mounted) {
        setState(() => _hasRated = true);
      }
    }
  }

  Future<void> _showDeliveryDialog(
    BuildContext context,
    String shipmentId,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const ShipmentOtpDialog(),
    );

    if (result == 'no_code') {
      _handleTrackingAction(shipmentId, 'markGoodsDelivered');
    } else if (result != null && result.isNotEmpty) {
      _handleTrackingActionWithCode(
        shipmentId,
        'markGoodsDeliveredWithCode',
        result,
      );
    }
  }

  Future<void> _handleTrackingActionWithCode(
    String shipmentId,
    String action,
    String code,
  ) async {
    try {
      setState(() => _isActionLoading = true);
      final service = ref.read(shipmentServiceProvider);
      if (action == 'markGoodsDeliveredWithCode') {
        await service.markGoodsDeliveredWithCode(shipmentId, code);
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

  Future<void> _handleTrackingAction(
    String shipmentId,
    String actionName,
  ) async {
    setState(() => _isActionLoading = true);
    final loc = AppLocalizations.of(context)!;
    try {
      final svc = ref.read(shipmentServiceProvider);
      switch (actionName) {
        case 'markGoodsHandedOver':
          await svc.markGoodsHandedOver(shipmentId);
          break;
        case 'confirmGoodsReceived':
          await svc.confirmGoodsReceived(shipmentId);
          break;
        case 'markPaymentSent':
          await svc.markPaymentSent(shipmentId);
          break;
        case 'confirmPaymentReceived':
          await svc.confirmPaymentReceived(shipmentId);
          break;
        case 'markGoodsDelivered':
          await svc.markGoodsDelivered(shipmentId);
          break;
        case 'confirmGoodsReceivedByClient':
          await svc.confirmGoodsReceivedByClient(shipmentId);
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.statusUpdated)));
      }
    } catch (e) {
      if (mounted) {
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

  // ─────────────────────────────────────────────────────────
  //  3. TABBED BOTTOM — TAB BAR
  // ─────────────────────────────────────────────────────────

  Widget _buildTabBar(ThemeData theme, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.hintColor,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 2.5,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.local_offer_outlined, size: 18),
            text: isArabic ? 'العرض' : 'Offer',
          ),
          Tab(
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            text: isArabic ? 'المحادثة' : 'Chat',
          ),
          Tab(
            icon: const Icon(Icons.history, size: 18),
            text: isArabic ? 'التحديثات' : 'Updates',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  3b. TIMELINE TAB
  // ─────────────────────────────────────────────────────────

  Widget _buildTimeline(ThemeData theme, bool isArabic) {
    final offer = _offer!;
    final events = <_TimelineEvent>[];

    // Offer created
    events.add(
      _TimelineEvent(
        icon: Icons.send_rounded,
        color: Colors.blue,
        title: isArabic ? 'تم إرسال العرض' : 'Offer Sent',
        subtitle: isArabic
            ? 'السعر: ${offer.price.toStringAsFixed(0)}'
            : 'Price: ${offer.price.toStringAsFixed(0)}',
        time: offer.createdAt,
      ),
    );

    // Status changes based on current status
    if (offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.completed) {
      events.add(
        _TimelineEvent(
          icon: Icons.check_circle,
          color: const Color(0xFF059669),
          title: isArabic ? 'تم قبول العرض' : 'Offer Accepted',
          subtitle: isArabic
              ? 'قبل صاحب الشحنة عرضك'
              : 'The shipment owner accepted your offer',
          time: offer.updatedAt ?? offer.createdAt,
        ),
      );

      // Add shipment lifecycle events
      final s = offer.shipment;
      if (s != null) {
        if (s.goodsHandedBySenderAt != null) {
          events.add(
            _TimelineEvent(
              icon: Icons.outbox,
              color: Colors.blue,
              title: isArabic ? 'تسليم الشحنة' : 'Goods Handed Over',
              subtitle: isArabic
                  ? 'تم تسليم الشحنة من قبل المرسل'
                  : 'Sender marked goods as handed over',
              time: s.goodsHandedBySenderAt!,
            ),
          );
        }
        if (s.goodsReceivedByDriverAt != null) {
          events.add(
            _TimelineEvent(
              icon: Icons.local_shipping,
              color: Colors.blue,
              title: isArabic ? 'استلام الشحنة' : 'Goods Received',
              subtitle: isArabic
                  ? 'تم استلام الشحنة من قبلك'
                  : 'You confirmed receiving the goods',
              time: s.goodsReceivedByDriverAt!,
            ),
          );
        }
        if (s.paymentMarkedBySenderAt != null) {
          events.add(
            _TimelineEvent(
              icon: Icons.payments,
              color: Colors.orange,
              title: isArabic ? 'إرسال الدفعة' : 'Payment Sent',
              subtitle: isArabic
                  ? 'قام المرسل بتحديد الدفعة كمرسلة'
                  : 'Sender marked payment as sent',
              time: s.paymentMarkedBySenderAt!,
            ),
          );
        }
        if (s.paymentConfirmedByDriverAt != null) {
          events.add(
            _TimelineEvent(
              icon: Icons.paid,
              color: Colors.green,
              title: isArabic ? 'تأكيد الدفعة' : 'Payment Confirmed',
              subtitle: isArabic
                  ? 'قمت بتأكيد استلام الدفعة'
                  : 'You confirmed receiving the payment',
              time: s.paymentConfirmedByDriverAt!,
            ),
          );
        }
        if (s.goodsDeliveredByDriverAt != null) {
          events.add(
            _TimelineEvent(
              icon: Icons.door_front_door,
              color: Colors.blue,
              title: isArabic ? 'توصيل الشحنة' : 'Goods Delivered',
              subtitle: isArabic
                  ? 'قمت بتحديد الشحنة كموصلة'
                  : 'You marked goods as delivered',
              time: s.goodsDeliveredByDriverAt!,
            ),
          );
        }
        if (s.goodsReceivedByClientAt != null) {
          events.add(
            _TimelineEvent(
              icon: Icons.task_alt,
              color: const Color(0xFF059669),
              title: isArabic ? 'اكتمال الرحلة' : 'Delivery Completed',
              subtitle: isArabic
                  ? 'تم تأكيد استلام الشحنة من قبل العميل'
                  : 'Client confirmed receipt of goods',
              time: s.goodsReceivedByClientAt!,
            ),
          );
        }
      }
    } else if (offer.status == OfferStatus.rejected) {
      events.add(
        _TimelineEvent(
          icon: Icons.cancel,
          color: Colors.red,
          title: isArabic ? 'تم رفض العرض' : 'Offer Rejected',
          subtitle: offer.rejectionReason == 'other_offer_accepted'
              ? (isArabic ? 'تم قبول عرض آخر' : 'Another offer was accepted')
              : (offer.rejectionReason ??
                    (isArabic ? 'بواسطة المرسل' : 'By sender')),
          time: offer.updatedAt ?? offer.createdAt,
        ),
      );
    } else if (offer.status == OfferStatus.cancelled) {
      events.add(
        _TimelineEvent(
          icon: Icons.block,
          color: Colors.grey,
          title: isArabic ? 'تم إلغاء العرض' : 'Offer Cancelled',
          subtitle: isArabic ? 'قمت بإلغاء العرض' : 'You cancelled the offer',
          time: offer.updatedAt ?? offer.createdAt,
        ),
      );
    }

    // Sort by time ascending first to maintain logical flow, then reverse for UI
    events.sort((a, b) => a.time.compareTo(b.time));
    final reversed = events.reversed.toList();

    if (reversed.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد تحديثات' : 'No updates yet',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final event = reversed[index];
        final isLast = index == reversed.length - 1;
        return _buildTimelineItem(theme, event, isLast);
      },
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    _TimelineEvent event,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline track
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(event.icon, size: 15, color: event.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (event.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.time.toLocal()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockReportMenu(BuildContext context) {
    if (_offer == null) return const SizedBox.shrink();
    final shipment = _offer!.shipment;
    if (shipment == null) return const SizedBox.shrink();

    final senderId = shipment.sender?.id ?? shipment.senderId;

    if (senderId.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'report') {
          _showReportDialog(context, senderId);
        } else if (value == 'block') {
          _showBlockDialog(context, senderId);
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
                      comment: 'Negotiation phase - Offer: ${_offer?.id}',
                      targetType: 'shipment',
                      targetShipmentId: _offer?.shipmentId,
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

// ─────────────────────────────────────────────────────────
//  Timeline event model (private)
// ─────────────────────────────────────────────────────────

class _TimelineEvent {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final DateTime time;

  const _TimelineEvent({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.time,
  });
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 64.0;
  @override
  double get maxExtent => 64.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
