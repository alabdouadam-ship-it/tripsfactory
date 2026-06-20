import 'package:flutter/material.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// A structured banner that communicates platform security and mediation
/// on high-stakes screens like booking confirmations, payment screens,
/// and trip posting.
class PlatformSecureBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final Key? testKey;

  const PlatformSecureBanner({
    super.key,
    this.message = 'This transaction is secured and logged by TripShip.',
    this.icon = Icons.lock_outline,
    this.color,
    this.testKey,
  });

  /// Used on payment screens
  factory PlatformSecureBanner.booking(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlatformSecureBanner(
      message: l10n.bookingSecuredLogged,
      icon: Icons.verified_user,
    );
  }

  factory PlatformSecureBanner.payment(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlatformSecureBanner(
      message: l10n.paymentDetailsSecure,
      icon: Icons.account_balance_wallet,
    );
  }

  factory PlatformSecureBanner.chat(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlatformSecureBanner(
      message: l10n.conversationSecuredModerated,
      icon: Icons.lock,
      testKey: const Key('chat_security_banner'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: testKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
