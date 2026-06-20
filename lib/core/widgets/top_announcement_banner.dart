import 'package:flutter/material.dart';
import 'package:tripsfactory/core/theme/tripsfactory_motion_tokens.dart';

/// Animated banner that slides down from the top on show,
/// and can be dismissed with a smooth fade+slide-up out animation.
///
/// Wrap with [AnimatedSlide]/[AnimatedOpacity] to handle entry.
/// The banner itself is stateful to handle the controlled entry animation.
class TopAnnouncementBanner extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const TopAnnouncementBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<TopAnnouncementBanner> createState() => _TopAnnouncementBannerState();
}

class _TopAnnouncementBannerState extends State<TopAnnouncementBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: TripsFactoryMotionTokens.full, // 220ms entry
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, -1.0), // starts fully above
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: TripsFactoryMotionTokens.curveOut,
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: TripsFactoryMotionTokens.curveOut),
    );

    // Auto-play entry on first build
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.animateBack(
      0,
      duration: TripsFactoryMotionTokens.mid, // 180ms exit
      curve: TripsFactoryMotionTokens.curveInOut,
    );
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionalTranslation(
          translation: _slideAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
