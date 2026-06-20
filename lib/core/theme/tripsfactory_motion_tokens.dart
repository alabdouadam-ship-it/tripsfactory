import 'package:flutter/material.dart';

/// Centralized motion tokens for TripsFactory Logistics.
///
/// All animations must be:
/// - Duration: 120–220ms
/// - Curve: easeOutCubic or easeInOutCubic
/// - Subtle, purposeful, non-bouncy
abstract final class TripsFactoryMotionTokens {
  // ─── Durations ────────────────────────────────────────────────
  /// 120ms — instant feedback (press-in, pulse)
  static const Duration fast = Duration(milliseconds: 120);

  /// 180ms — state transitions, cross-fades, badge updates
  static const Duration mid = Duration(milliseconds: 180);

  /// 220ms — screen-level transitions, dialogs, banners
  static const Duration full = Duration(milliseconds: 220);

  // ─── Curves ───────────────────────────────────────────────────
  /// For exits and deceleration (most common)
  static const Curve curveOut = Curves.easeOutCubic;

  /// For enter + exit arcs (dialogs, banners, state switches)
  static const Curve curveInOut = Curves.easeInOutCubic;

  // ─── Tap Feedback ─────────────────────────────────────────────
  /// Max press-in scale factor for tap feedback
  static const double tapScaleDown = 0.97;

  /// Opacity during pressed state
  static const double tapOpacityPressed = 0.88;
}
