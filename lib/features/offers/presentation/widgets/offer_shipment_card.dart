import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class OfferShipmentCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onSenderTap;

  const OfferShipmentCard({
    super.key,
    required this.offer,
    required this.onSenderTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = AppLocalizations.of(context)!;

    final shipment = offer.shipment;
    if (shipment == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          isArabic ? 'معلومات الشحنة غير متوفرة' : 'Shipment info unavailable',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    final pickupLoc = shipment.pickupLocation;
    final dropoffLoc = shipment.dropoffLocation;
    final isExternal = Location.isExternalTrip(pickupLoc, dropoffLoc);
    final pickup =
        pickupLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '—';
    final dropoff =
        dropoffLoc?.formatLabel(isArabic, isExternal: isExternal) ?? '—';
    final date = shipment.pickupDate ?? shipment.createdAt;
    final senderName =
        shipment.sender?.fullName ?? (isArabic ? 'مرسل' : 'Sender');
    final senderAvatar = shipment.sender?.avatarUrl;
    final hasAvatar = senderAvatar != null && senderAvatar.trim().isNotEmpty;

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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: route + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    Icon(
                      Icons.trip_origin,
                      size: 14,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pickup,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: Icon(
                    Icons.more_vert,
                    size: 14,
                    color: theme.hintColor,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dropoff,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Weight + date chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (shipment.weightKg > 0)
                      _chip(
                        theme,
                        Icons.scale_outlined,
                        '${shipment.weightKg.toStringAsFixed(0)} kg',
                      ),
                    _chip(
                      theme,
                      Icons.calendar_today_outlined,
                      DateFormat.MMMd().format(date),
                    ),
                    _chip(
                      theme,
                      isExternal ? Icons.public : Icons.home_outlined,
                      isExternal ? loc.international : loc.domestic,
                      backgroundColor: isExternal
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      textColor: isExternal ? Colors.red : Colors.green,
                      iconColor: isExternal ? Colors.red : Colors.green,
                    ),
                  ],
                ),

                // Description
                if (shipment.description != null &&
                    shipment.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    shipment.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: sender avatar + name (tappable)
          GestureDetector(
            onTap: onSenderTap,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: hasAvatar
                      ? NetworkImage(senderAvatar)
                      : null,
                  child: !hasAvatar ? const Icon(Icons.person, size: 22) : null,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    senderName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                Icon(Icons.open_in_new, size: 12, color: theme.hintColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    ThemeData theme,
    IconData icon,
    String label, {
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? theme.hintColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
