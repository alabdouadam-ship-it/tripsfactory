import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_status_badge.dart';
import 'package:tripship/core/widgets/trust_badge.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// Offer card used in ShipmentDetailsScreen (sender/company view).
/// Shows driver info, price, message, and action buttons based on offer status.
class OfferCard extends StatelessWidget {
  final Offer offer;
  final bool isPinned;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onChat;

  const OfferCard({
    super.key,
    required this.offer,
    this.isPinned = false,
    this.onAccept,
    this.onReject,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driver = offer.driver;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final driverName = driver?.fullName ?? (isArabic ? 'غير معروف' : 'Unknown');
    final avatarUrl = driver?.avatarUrl;
    final rating = driver?.travelerRatingAvg?.toStringAsFixed(1) ?? '0.0';
    final vehicleType = driver?.travelerType == DomainConfig.travelerWithVehicle
        ? (isArabic ? 'سائق بمركبة' : 'Driver with vehicle')
        : null;

    final bgColor = theme.brightness == Brightness.dark
        ? Colors.blue.withValues(alpha: 0.1)
        : Colors.blue.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPinned
              ? const Color(0xFF059669).withValues(alpha: 0.5)
              : theme.dividerColor,
          width: isPinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Avatar + Name + Rating + Badge
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.trim().isEmpty)
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openProfile(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                driverName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (driver != null &&
                                TrustBadge.fromProfileBadge(
                                      trustBadge: driver.trustBadge,
                                      isTrusted: driver.isTrusted,
                                      isFeatured: driver.isFeatured,
                                      showLabel: false,
                                      iconSize: 12,
                                    ) !=
                                    null) ...[
                              const SizedBox(width: 6),
                              TrustBadge.fromProfileBadge(
                                trustBadge: driver.trustBadge,
                                isTrusted: driver.isTrusted,
                                isFeatured: driver.isFeatured,
                                showLabel: false,
                                iconSize: 12,
                              )!,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            rating,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          if (vehicleType != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 13,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                vehicleType,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.hintColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                OfferStatusBadge(status: offer.status, compact: true),
              ],
            ),

            // ── Price
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  offer.price.toStringAsFixed(0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            // ── Message
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.message!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
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
                          ? (isArabic
                                ? 'تم رفض العرض تلقائياً: تم قبول عرض آخر'
                                : 'Auto-rejected: another offer was accepted')
                          : offer.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Action buttons
            if (offer.status == OfferStatus.sent ||
                offer.status == OfferStatus.accepted) ...[
              const SizedBox(height: 14),
              Divider(
                color: theme.dividerColor.withValues(alpha: 0.5),
                height: 1,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onChat != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: Text(AppLocalizations.of(context)!.chatAction),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  if (offer.status == OfferStatus.sent &&
                      (onAccept != null || onReject != null)) ...[
                    if (onChat != null) const SizedBox(width: 8),
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.rejectAction,
                          ),
                        ),
                      ),
                    if (onReject != null && onAccept != null)
                      const SizedBox(width: 8),
                    if (onAccept != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.acceptAction,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    final driver = offer.driver;
    if (driver == null) return;
    context.push(
      '/traveler-profile',
      extra: {
        'driverId': driver.id,
        'driverName': driver.fullName,
        'role': 'driver',
      },
    );
  }
}
