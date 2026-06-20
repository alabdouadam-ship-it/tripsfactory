import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/profile/data/profile_model.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/core/config/domain_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:go_router/go_router.dart';

import 'package:tripsfactory/core/widgets/animated_card.dart';
import 'package:tripsfactory/core/widgets/trust_badge.dart';
import 'package:tripsfactory/core/widgets/tripsfactory_expandable_text.dart';
import 'package:tripsfactory/core/theme/tripsfactory_design_tokens.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onCopyTrip;
  final VoidCallback? onShareTrip;
  final Duration? delay;
  final BookingStatus? bookingStatus;
  final DateTime? requestedAt;
  final EdgeInsetsGeometry? margin;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onDelete,
    this.onCopyTrip,
    this.onShareTrip,
    this.delay,
    this.bookingStatus,
    this.requestedAt,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final originLoc = trip.originLocation;
    final destLoc = trip.destLocation;
    final isExternal = Location.isExternalTrip(originLoc, destLoc);

    final origin =
        originLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';
    final dest = destLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '';

    final date = trip.departureTime;
    final fmtDate = DateFormat.MMMd().add_jm().format(date);

    final maxWeight = trip.maxWeightKg;
    final status = trip.status;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Subtle background color depending on internal/external
    final cardBgColor = isExternal
        ? (isDarkMode
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFFFFEBEE)) // Light Red
        : (isDarkMode
              ? Colors.green.withValues(alpha: 0.1)
              : const Color(0xFFE8F5E9)); // Light Green

    // Subtle border color
    final borderColor = isExternal
        ? Colors.red.withValues(alpha: 0.3)
        : Colors.green.withValues(alpha: 0.3);

    final card = AnimatedCard(
      onTap: onTap,
      child: Container(
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: TripsFactoryDesignTokens.shadowLevel1(context),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress:
                (onCopyTrip != null || onShareTrip != null || onDelete != null)
                ? () => _showTripOptions(context)
                : null,
            borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Status and Delete Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Box
                      InkWell(
                        onTap: () => context.push(
                          '/traveler-profile',
                          extra: {
                            'driverId': trip.driverId,
                            'driverName':
                                trip.driver?.fullName ??
                                AppLocalizations.of(context)!.unknownTraveler,
                            'role': trip.driver?.isDriver == true
                                ? 'driver'
                                : 'sender',
                          },
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              (trip.driver?.avatarUrl != null &&
                                  trip.driver!.avatarUrl!.trim().isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: trip.driver!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 24,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Route Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  origin,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  dest,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // More options menu (Three-dot)
                      if (onShareTrip != null ||
                          onCopyTrip != null ||
                          onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showTripOptions(context),
                          tooltip: AppLocalizations.of(
                            context,
                          )!.shareTrip, // Kept for backwards translation compatibility
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTransportBadge(context, isExternal),
                        if (trip.driver != null) ...[
                          const SizedBox(width: 8),
                          _buildTravelerTypeBadge(context, trip.driver!),
                        ],
                        if (trip.driver?.travelerStatus == DomainConfig.statusApproved) ...[
                          const SizedBox(width: 8),
                          TrustBadge.verified(showLabel: false, iconSize: 12),
                        ],
                        if (trip.driver != null)
                          ..._buildProfileBadge(trip.driver!),
                        if (trip.driver?.promotedUntil != null &&
                            trip.driver!.promotedUntil!.isAfter(
                              DateTime.now(),
                            )) ...[
                          const SizedBox(width: 8),
                          _buildPromotedBadge(context),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 12),

                  // Details (Date, Capacity, Price)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date + Status badges (scrollable to prevent overflow)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                fmtDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusBadge(context, status),
                              if (bookingStatus != null) ...[
                                const SizedBox(width: 8),
                                _buildBookingBadge(context, bookingStatus!),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Metrics Row for Weight & Price
                      Row(
                        children: [
                          if (maxWeight != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius:
                                    TripsFactoryDesignTokens.borderRadiusSmall,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 12,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${maxWeight.toStringAsFixed(0)} ${AppLocalizations.of(context)!.kg}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                  ),

                  if (trip.notes != null && trip.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TripsFactoryExpandableText(
                      text: trip.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],

                  if (requestedAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${AppLocalizations.of(context)!.requestedOnLabel}: ${DateFormat('yyyy-MM-dd HH:mm').format(requestedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Only apply flutter_animate fadeIn when used in lists (delay != null).
    // Skipping avoids the internal Stack that triggers semantics.parentDataDirty
    // inside SingleChildScrollView.
    if (delay != null) {
      return card.animate(delay: delay).fadeIn(duration: 300.ms);
    }
    return card;
  }

  void _showTripOptions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onCopyTrip != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(loc.copyTrip),
                onTap: () {
                  Navigator.pop(ctx);
                  onCopyTrip?.call();
                },
              ),
            if (onShareTrip != null)
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(loc.shareTrip),
                onTap: () {
                  Navigator.pop(ctx);
                  onShareTrip?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  loc.delete,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportBadge(BuildContext context, bool isExternal) {
    final localizations = AppLocalizations.of(context)!;
    final color = isExternal ? Colors.red : Colors.green;
    final label = isExternal
        ? localizations.externalShipping
        : localizations.internalShipping;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, TripStatus status) {
    final localizations = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case TripStatus.available:
        color = Colors.green;
        label = localizations.statusPending;
        break;
      case TripStatus.inCommunication:
        color = Colors.blue;
        label = localizations.statusInCommunication;
        break;
      case TripStatus.pendingConfirmation:
        color = Colors.orange;
        label = localizations.statusPending;
        break;
      case TripStatus.booked:
        color = Colors.amber;
        label = localizations.statusBooked;
        break;
      case TripStatus.inTransit:
        color = Colors.purple;
        label = localizations.inTransitBadge;
        break;
      case TripStatus.full:
        color = Colors.red;
        label = localizations.markTripAsFull;
        break;
      case TripStatus.completed:
        color = Colors.green;
        label = localizations.completedBadge;
        break;
      case TripStatus.cancelled:
        color = Colors.red;
        label = localizations.statusCancelled;
        break;
    }

    return Row(
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingBadge(BuildContext context, BookingStatus status) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    Color color;
    String label;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        label = isArabic ? 'طلب مرسل' : 'Requested';
        break;
      case BookingStatus.inCommunication:
        color = Colors.blue;
        label = isArabic ? 'قيد التواصل' : 'In Communication';
        break;
      case BookingStatus.accepted:
        color = Colors.green;
        label = isArabic ? 'مقبول' : 'Accepted';
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
      case BookingStatus.inTransit:
        color = Colors.purple;
        label = isArabic ? 'قيد التوصيل' : 'In Transit';
        break;
      case BookingStatus.delivered:
        color = const Color(0xFF0F9D58);
        label = isArabic ? 'تم التوصيل' : 'Delivered';
        break;
      case BookingStatus.completed:
        color = Colors.teal;
        label = isArabic ? 'مكتمل' : 'Completed';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = isArabic ? 'ملغي' : 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTravelerTypeBadge(BuildContext context, Profile driver) {
    final loc = AppLocalizations.of(context)!;
    final vehicle = driver.vehicles.isNotEmpty ? driver.vehicles.first : null;
    final label = driver.isDriver
        ? (vehicle != null
              ? _getVehicleLabel(loc, vehicle.vehicleType)
              : loc.driverLabel)
        : loc.travelerAsPerson;
    final color = driver.isDriver ? Colors.blue : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            driver.isDriver ? Icons.directions_car : Icons.person,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotedBadge(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
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

  String _getVehicleLabel(AppLocalizations loc, String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return loc.car;
      case 'sedan':
        return loc.sedan;
      case 'van':
        return loc.van;
      case 'truck':
        return loc.truck;
      case 'bus':
        return loc.bus;
      case 'tractortrailer':
      case 'tractor_trailer':
        return loc.tractorTrailer;
      case 'largecar':
      case 'large_car':
        return loc.largeCar;
      case 'mediumcar':
      case 'medium_car':
        return loc.mediumCar;
      case 'smallcar':
      case 'small_car':
        return loc.smallCar;
      case 'refrigerated':
        return loc.refrigerated;
      default:
        return vehicleType;
    }
  }

  List<Widget> _buildProfileBadge(Profile driver) {
    final badge = TrustBadge.fromProfileBadge(
      trustBadge: driver.trustBadge,
      isTrusted: driver.isTrusted,
      isFeatured: driver.isFeatured,
      showLabel: false,
      iconSize: 12,
    );
    if (badge == null) return const [];
    return [const SizedBox(width: 8), badge];
  }
}
