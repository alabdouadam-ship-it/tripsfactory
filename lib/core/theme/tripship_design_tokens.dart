import 'package:flutter/material.dart';

/// A central repository for TripShip's SaaS-level visual hierarchy tokens.
/// Adheres strictly to a 3-level elevation system to maintain
/// "regulated logistics infrastructure" aesthetics.
class TripShipDesignTokens {
  // --- Standardized Border Radii ---
  /// Robust, snappy interactions (Buttons, Inputs, Small Chips)
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(8);

  /// Friendly but structured containers (Cards, Banners, Form Groups)
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(16);

  /// Highest elevation, distinct from page constraints (Dialogs, Bottom Sheets)
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(24);

  // --- 3-Level Elevation & Shadow System ---

  /// Level 0: Pure surface backgrounds.
  /// (Use on Scaffold, base Lists. No shadow.)
  static const List<BoxShadow> shadowLevel0 = [];

  /// Level 1: Form sections, interactive cards, structural grouping.
  /// Soft, tight, professional drop-shadow.
  static List<BoxShadow> shadowLevel1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Level 2: Overlays, Contextual Menus, Dialogs, Floating Bottom Banners.
  /// Diffused, deep shadow emphasizing heavy Z-axis separation.
  static List<BoxShadow> shadowLevel2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.08),
        blurRadius: 40,
        spreadRadius: -4,
        offset: const Offset(0, 16),
      ),
    ];
  }
}
