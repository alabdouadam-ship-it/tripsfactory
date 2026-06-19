import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/features/offers/data/offer_providers.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/widgets/notification_bell_button.dart';

enum _ShipmentFilter {
  all,
  waiting,
  hasOffers,
  accepted,
  inProgress,
  completed,
}

class MyShipmentsScreen extends ConsumerStatefulWidget {
  const MyShipmentsScreen({super.key});

  @override
  ConsumerState<MyShipmentsScreen> createState() => _MyShipmentsScreenState();
}

class _MyShipmentsScreenState extends ConsumerState<MyShipmentsScreen> {
  _ShipmentFilter _filter = _ShipmentFilter.all;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final asyncData = ref.watch(myShipmentsWithOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myShipments),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.postShipment,
            onPressed: () => context.push(AppRoutes.postShipment),
          ),
          const NotificationBellButton(),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(_ShipmentFilter.all, loc.all),
                _chip(_ShipmentFilter.waiting, loc.statusPending),
                _chip(_ShipmentFilter.hasOffers, loc.offersReceived),
                _chip(_ShipmentFilter.accepted, loc.statusAccepted),
                _chip(_ShipmentFilter.inProgress, loc.inTransitBadge),
                _chip(_ShipmentFilter.completed, loc.statusCompleted),
              ],
            ),
          ),

          // ── List
          Expanded(
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(loc.unexpectedError)),
              data: (items) {
                final filtered = _applyFilter(items);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: theme.hintColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.noShipmentsFound,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _buildShipmentCard(context, filtered[i], loc, isArabic),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(_ShipmentFilter f, String label) {
    final isSelected = _filter == f;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = f),
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

  List<ShipmentWithOfferCount> _applyFilter(
    List<ShipmentWithOfferCount> items,
  ) {
    final filtered = items.where((item) {
      final s = item.shipment.status;
      switch (_filter) {
        case _ShipmentFilter.all:
          return true;
        case _ShipmentFilter.waiting:
          return s == ShipmentStatus.pending && item.totalOffers == 0;
        case _ShipmentFilter.hasOffers:
          return item.pendingOffers > 0;
        case _ShipmentFilter.accepted:
          return s == ShipmentStatus.accepted;
        case _ShipmentFilter.inProgress:
          return s == ShipmentStatus.pickedUp || s == ShipmentStatus.inTransit;
        case _ShipmentFilter.completed:
          return s == ShipmentStatus.delivered || s == ShipmentStatus.completed;
      }
    }).toList();

    // Sort: needs-decision first, then active, then completed
    filtered.sort((a, b) {
      int priority(ShipmentWithOfferCount item) {
        if (item.pendingOffers > 0) return 0;
        if (item.hasAccepted) return 1;
        if (item.shipment.status == ShipmentStatus.pickedUp) return 2;
        if (item.shipment.status == ShipmentStatus.inTransit) return 2;
        if (item.shipment.status == ShipmentStatus.delivered) return 3;
        if (item.shipment.status == ShipmentStatus.completed) return 3;
        if (item.shipment.status == ShipmentStatus.cancelled) return 4;
        return 1;
      }

      final cmp = priority(a).compareTo(priority(b));
      if (cmp != 0) return cmp;
      return b.shipment.createdAt.compareTo(a.shipment.createdAt);
    });

    return filtered;
  }

  Widget _buildShipmentCard(
    BuildContext context,
    ShipmentWithOfferCount item,
    AppLocalizations loc,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    final shipment = item.shipment;
    final pickupLoc = shipment.pickupLocation;
    final dropoffLoc = shipment.dropoffLocation;
    final isExternal = Location.isExternalTrip(pickupLoc, dropoffLoc);
    final pickup =
        pickupLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final dropoff =
        dropoffLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final date = shipment.pickupDate ?? shipment.createdAt;
    final needsDecision = item.pendingOffers > 0;

    final isDarkMode = theme.brightness == Brightness.dark;
    final cardBgColor = isExternal
        ? (isDarkMode
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFFFFEBEE)) // Light Red
        : (isDarkMode
              ? Colors.green.withValues(alpha: 0.1)
              : const Color(0xFFE8F5E9)); // Light Green

    final borderColor = isExternal
        ? Colors.red.withValues(alpha: 0.3)
        : Colors.green.withValues(alpha: 0.3);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: needsDecision
              ? Colors.orange.withValues(alpha: 0.5)
              : borderColor,
          width: needsDecision ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.shipmentDetails, extra: shipment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Route
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.trip_origin,
                    size: 16,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Icon(
                            Icons.arrow_downward,
                            size: 16,
                            color: theme.hintColor,
                          ),
                        ),
                        Text(
                          dropoff,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Meta row: weight + date + transport badge
              Row(
                children: [
                  if (shipment.weightKg > 0) ...[
                    Icon(
                      Icons.scale_outlined,
                      size: 13,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${shipment.weightKg.toStringAsFixed(0)} kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.MMMd().format(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const Spacer(),
                  _buildTransportBadge(isExternal, loc),
                ],
              ),

              const SizedBox(height: 10),
              Divider(
                color: theme.dividerColor.withValues(alpha: 0.4),
                height: 1,
              ),
              const SizedBox(height: 10),

              // ── Bottom: status badge + offers count
              Row(
                children: [
                  _buildShipmentStatusBadge(shipment.status, loc),
                  const Spacer(),
                  if (item.totalOffers > 0) ...[
                    if (needsDecision)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      '${item.totalOffers} ${loc.myOffers}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: needsDecision
                            ? Colors.orange.shade700
                            : theme.hintColor,
                      ),
                    ),
                  ],
                  if (item.hasAccepted) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.verified,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShipmentStatusBadge(
    ShipmentStatus status,
    AppLocalizations loc,
  ) {
    final (Color color, String label) = switch (status) {
      ShipmentStatus.pending => (Colors.orange, loc.statusPending),
      ShipmentStatus.inCommunication => (
        Colors.blue,
        loc.statusInCommunication,
      ),
      ShipmentStatus.accepted => (const Color(0xFF059669), loc.statusAccepted),
      ShipmentStatus.pickedUp => (Colors.purple, loc.statusPickedUp),
      ShipmentStatus.inTransit => (Colors.deepPurple, loc.inTransitBadge),
      ShipmentStatus.delivered => (Colors.teal, loc.statusDelivered),
      ShipmentStatus.completed => (Colors.green, loc.statusCompleted),
      ShipmentStatus.cancelled => (Colors.grey, loc.statusCancelled),
      ShipmentStatus.expired => (
        Colors.grey,
        loc.localeName == 'ar' ? 'منتهية الصلاحية' : 'Expired',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTransportBadge(bool isExternal, AppLocalizations loc) {
    final color = isExternal ? Colors.red.shade700 : Colors.green.shade700;
    final label = isExternal ? loc.externalShipping : loc.internalShipping;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
