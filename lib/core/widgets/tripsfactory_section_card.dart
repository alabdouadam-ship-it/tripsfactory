import 'package:flutter/material.dart';
import 'package:tripsfactory/core/theme/tripsfactory_design_tokens.dart';

class TripsFactorySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const TripsFactorySectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.08 : 0.05,
          ),
          width: 1,
        ),
        boxShadow: TripsFactoryDesignTokens.shadowLevel1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}
