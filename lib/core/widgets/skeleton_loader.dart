import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonLoader.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = size / 2,
      shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Standardized Zinc-inspired tokens
    final baseColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);
    final highlightColor = isDark
        ? const Color(0xFF3F3F46)
        : const Color(0xFFF4F4F5);
    final containerColor = isDark ? Colors.black26 : Colors.white70;

    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: containerColor,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(borderRadius)
                : null,
          ),
        ),
      ),
    );
  }
}

class ShipmentCardSkeleton extends StatelessWidget {
  const ShipmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBgColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(width: 150, height: 16),
                    const SizedBox(height: 8),
                    const SkeletonLoader(width: 120, height: 16),
                  ],
                ),
              ),
              const SkeletonLoader(width: 60, height: 24, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLoader(width: 100, height: 14),
              const SkeletonLoader(width: 70, height: 24, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBgColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader(width: 40, height: 40, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: SkeletonLoader(width: 50, height: 16),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const Flexible(
                          child: SkeletonLoader(width: 50, height: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const SkeletonLoader(width: 100, height: 12),
                  ],
                ),
              ),
              const SkeletonLoader(width: 70, height: 24, borderRadius: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class ShipmentDetailsSkeleton extends StatelessWidget {
  const ShipmentDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: double.infinity, height: 150),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 180, height: 24),
                const SizedBox(height: 16),
                const SkeletonLoader(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const SkeletonLoader(width: double.infinity, height: 16),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonLoader(width: 80, height: 40),
                    SkeletonLoader(width: 80, height: 40),
                    SkeletonLoader(width: 80, height: 40),
                  ],
                ),
                const SizedBox(height: 32),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TripDetailsSkeleton extends StatelessWidget {
  const TripDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: double.infinity, height: 200),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 150, height: 24),
                const SizedBox(height: 16),
                const SkeletonLoader(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const SkeletonLoader(width: double.infinity, height: 16),
                const SizedBox(height: 24),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
