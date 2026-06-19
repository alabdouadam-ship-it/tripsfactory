import 'package:flutter/material.dart';
import 'package:tripship/core/enums/app_enums.dart';

class OfferStatusBadge extends StatelessWidget {
  final OfferStatus status;
  final bool compact;

  const OfferStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusConfig(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, String) _statusConfig(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    switch (status) {
      case OfferStatus.sent:
        return (Colors.orange, isArabic ? 'مرسل' : 'Sent');
      case OfferStatus.accepted:
        return (const Color(0xFF059669), isArabic ? 'مقبول' : 'Accepted');
      case OfferStatus.rejected:
        return (Colors.red, isArabic ? 'مرفوض' : 'Rejected');
      case OfferStatus.cancelled:
        return (Colors.grey, isArabic ? 'ملغى' : 'Cancelled');
      case OfferStatus.completed:
        return (const Color(0xFF059669), isArabic ? 'مكتمل' : 'Completed');
    }
  }
}
