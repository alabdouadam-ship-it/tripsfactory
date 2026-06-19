import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum TrustBadgeVariant {
  verified,
  platformProtected,
  licenseVerified,
  trusted,
  featured,
  verifiedPartner,
}

class TrustBadge extends StatelessWidget {
  final TrustBadgeVariant variant;
  final bool showLabel;
  final double iconSize;

  const TrustBadge({
    super.key,
    required this.variant,
    this.showLabel = true,
    this.iconSize = 12,
  });

  // Factory constructors for backward compatibility or convenience
  factory TrustBadge.verified({bool showLabel = true, double iconSize = 12}) =>
      TrustBadge(
        variant: TrustBadgeVariant.verified,
        showLabel: showLabel,
        iconSize: iconSize,
      );

  factory TrustBadge.protected({bool showLabel = true, double iconSize = 12}) =>
      TrustBadge(
        variant: TrustBadgeVariant.platformProtected,
        showLabel: showLabel,
        iconSize: iconSize,
      );

  factory TrustBadge.license({bool showLabel = true, double iconSize = 12}) =>
      TrustBadge(
        variant: TrustBadgeVariant.licenseVerified,
        showLabel: showLabel,
        iconSize: iconSize,
      );

  factory TrustBadge.trusted({bool showLabel = true, double iconSize = 12}) =>
      TrustBadge(
        variant: TrustBadgeVariant.trusted,
        showLabel: showLabel,
        iconSize: iconSize,
      );

  factory TrustBadge.featured({bool showLabel = true, double iconSize = 12}) =>
      TrustBadge(
        variant: TrustBadgeVariant.featured,
        showLabel: showLabel,
        iconSize: iconSize,
      );

  factory TrustBadge.verifiedPartner({
    bool showLabel = true,
    double iconSize = 12,
  }) => TrustBadge(
    variant: TrustBadgeVariant.verifiedPartner,
    showLabel: showLabel,
    iconSize: iconSize,
  );

  static TrustBadge? fromProfileBadge({
    required String? trustBadge,
    required bool isTrusted,
    required bool isFeatured,
    bool showLabel = false,
    double iconSize = 12,
  }) {
    switch (trustBadge) {
      case 'featured_driver':
      case 'featured_company':
        return TrustBadge.featured(showLabel: showLabel, iconSize: iconSize);
      case 'trusted_driver':
      case 'trusted_company':
        return TrustBadge.trusted(showLabel: showLabel, iconSize: iconSize);
      case 'verified_partner':
        return TrustBadge.verifiedPartner(
          showLabel: showLabel,
          iconSize: iconSize,
        );
    }
    if (isFeatured) {
      return TrustBadge.featured(showLabel: showLabel, iconSize: iconSize);
    }
    if (isTrusted) {
      return TrustBadge.trusted(showLabel: showLabel, iconSize: iconSize);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final config = _getVariantConfig(l10n);
    final testKey = _getTestKey();

    return Semantics(
      label: config.label,
      child: Container(
        key: testKey,
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 8 : 4,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: config.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: iconSize, color: config.color),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                config.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: config.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({IconData icon, String label, Color color}) _getVariantConfig(
    AppLocalizations l10n,
  ) {
    switch (variant) {
      case TrustBadgeVariant.verified:
        return (
          icon: Icons.verified_outlined,
          label: l10n.verified,
          color: const Color(0xFF0F9D58), // Verified green
        );
      case TrustBadgeVariant.platformProtected:
        return (
          icon: Icons.shield_outlined,
          label: l10n.platformProtected,
          color: const Color(0xFF2563EB), // Trusted blue
        );
      case TrustBadgeVariant.licenseVerified:
        return (
          icon: Icons.badge_outlined,
          label: l10n.licenseVerified,
          color: const Color(0xFF0284C7), // Sky blue
        );
      case TrustBadgeVariant.trusted:
        return (
          icon: Icons.verified_user_outlined,
          label: l10n.platformProtected,
          color: const Color(0xFF0F9D58),
        );
      case TrustBadgeVariant.featured:
        return (
          icon: Icons.star_outline,
          label: l10n.promotedBadge,
          color: const Color(0xFFF59E0B),
        );
      case TrustBadgeVariant.verifiedPartner:
        return (
          icon: Icons.workspace_premium_outlined,
          label: l10n.verified,
          color: const Color(0xFF7C3AED),
        );
    }
  }

  Key? _getTestKey() {
    switch (variant) {
      case TrustBadgeVariant.verified:
        return const Key('badge_verified_traveler');
      case TrustBadgeVariant.licenseVerified:
        return const Key('badge_license_valid');
      case TrustBadgeVariant.platformProtected:
        return const Key('badge_platform_protected');
      case TrustBadgeVariant.trusted:
        return const Key('badge_trusted_profile');
      case TrustBadgeVariant.featured:
        return const Key('badge_featured_profile');
      case TrustBadgeVariant.verifiedPartner:
        return const Key('badge_verified_partner');
    }
  }
}
