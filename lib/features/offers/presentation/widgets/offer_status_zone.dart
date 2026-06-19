import 'package:flutter/material.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/features/offers/presentation/widgets/offer_status_badge.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class OfferStatusZone extends StatelessWidget {
  final Offer offer;
  final bool isActionLoading;
  final VoidCallback onCancelOffer;
  final Widget? trackingSection;

  const OfferStatusZone({
    super.key,
    required this.offer,
    required this.isActionLoading,
    required this.onCancelOffer,
    this.trackingSection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = AppLocalizations.of(context)!;
    final statusColor = _offerStatusColor(offer.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Status row: badge + price
          Row(
            children: [
              OfferStatusBadge(status: offer.status),
              const Spacer(),
              Icon(
                Icons.payments_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                offer.price.toStringAsFixed(0),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          // Rejection reason
          if (offer.status == OfferStatus.rejected &&
              offer.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
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
            ),
          ],

          // Initial message
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '💬 ${offer.message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: theme.hintColor,
                ),
              ),
            ),
          ],

          // Action button: cancel offer (only when status is 'sent')
          if (offer.status == OfferStatus.sent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isActionLoading ? null : onCancelOffer,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(loc.cancelOffer),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // Action button: view shipment tracking (when accepted or completed)
          if ((offer.status == OfferStatus.accepted ||
                  offer.status == OfferStatus.completed) &&
              trackingSection != null) ...[
            const SizedBox(height: 16),
            trackingSection!,
          ],
        ],
      ),
    );
  }

  Color _offerStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.sent:
        return Colors.orange;
      case OfferStatus.accepted:
      case OfferStatus.completed:
        return const Color(0xFF059669);
      case OfferStatus.rejected:
        return Colors.red;
      case OfferStatus.cancelled:
        return Colors.grey;
    }
  }
}
