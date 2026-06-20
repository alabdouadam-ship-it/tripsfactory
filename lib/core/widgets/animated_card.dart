import 'package:flutter/material.dart';
import 'package:tripsfactory/core/theme/tripsfactory_motion_tokens.dart';

/// A card wrapper that provides a subtle press-in scale + opacity animation on tap.
///
/// Uses [AnimatedBuilder] + [Transform.scale] instead of [ScaleTransition]
/// to avoid the `!semantics.parentDataDirty` assertion that occurs when
/// [ScaleTransition] runs concurrently with other layout-affecting renders.
///
/// [Transform.scale] is paint-only and never invalidates semantics parent data.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedCard({super.key, required this.child, this.onTap});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: TripsFactoryMotionTokens.fast, // 120ms press-in
    );
    _scaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: TripsFactoryMotionTokens.tapScaleDown, // 0.97
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: TripsFactoryMotionTokens.curveOut,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.animateBack(
        0,
        duration: TripsFactoryMotionTokens.mid,
      ); // 180ms release
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.animateBack(0, duration: TripsFactoryMotionTokens.mid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
