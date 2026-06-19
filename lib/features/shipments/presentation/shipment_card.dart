import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/widgets/trust_badge.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;
  final Duration? delay;

  const ShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final pickupLoc = shipment.pickupLocation;
    final dropoffLoc = shipment.dropoffLocation;

    final isExternal = Location.isExternalTrip(pickupLoc, dropoffLoc);

    final pickup =
        pickupLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final dropoff =
        dropoffLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final description = shipment.description ?? '';
    final status = shipment.status;
    final price = shipment.diffPrice;
    final date = shipment.pickupDate ?? shipment.createdAt;

    final theme = Theme.of(context);
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        // Border color based on type
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationRow(
                            context,
                            Icons.trip_origin,
                            pickup,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildLocationRow(
                            context,
                            Icons.location_on,
                            dropoff,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(context, status),
                        if (shipment.sender?.promotedUntil != null &&
                            shipment.sender!.promotedUntil!.isAfter(
                              DateTime.now(),
                            )) ...[
                          const SizedBox(height: 8),
                          _buildPromotedBadge(context),
                        ],
                        if (shipment.sender != null)
                          ..._buildProfileBadge(shipment.sender!),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),

                const SizedBox(height: 12),

                // Description (if available)
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer with Date, Weight, Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date & Weight
                    Row(
                      children: [
                        if (true) ...[
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat.MMMd().format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Transport Type Badge
                    _buildTransportBadge(context, isExternal),

                    // Price
                    if (price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.2),
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$price',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate(delay: delay).fadeIn(duration: 300.ms),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final statusConfig = _getStatusConfig(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusConfig['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusConfig['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusConfig['label'],
            style: TextStyle(
              color: statusConfig['color'],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(
    BuildContext context,
    ShipmentStatus status,
  ) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case ShipmentStatus.accepted:
        return {
          'label': localizations.statusAccepted,
          'color': const Color(0xFF059669),
        };
      case ShipmentStatus.pickedUp:
      case ShipmentStatus.inTransit:
        return {'label': localizations.inTransitBadge, 'color': Colors.purple};
      case ShipmentStatus.pending:
        return {'label': localizations.statusPending, 'color': Colors.orange};
      case ShipmentStatus.inCommunication:
        return {
          'label': localizations.statusInCommunication,
          'color': Colors.blue,
        };
      case ShipmentStatus.delivered:
        return {'label': localizations.statusDelivered, 'color': Colors.teal};
      case ShipmentStatus.completed:
        return {'label': localizations.completedBadge, 'color': Colors.green};
      case ShipmentStatus.cancelled:
        return {'label': localizations.statusCancelled, 'color': Colors.red};
      case ShipmentStatus.expired:
        return {
          'label': Localizations.localeOf(context).languageCode == 'ar'
              ? 'منتهية الصلاحية'
              : 'Expired',
          'color': Colors.grey,
        };
    }
  }

  Widget _buildPromotedBadge(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 10, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            localizations.promotedBadge,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileBadge(Profile sender) {
    final badge = TrustBadge.fromProfileBadge(
      trustBadge: sender.trustBadge,
      isTrusted: sender.isTrusted,
      isFeatured: sender.isFeatured,
      showLabel: false,
      iconSize: 12,
    );
    if (badge == null) return const [];
    return [const SizedBox(height: 8), badge];
  }
}
