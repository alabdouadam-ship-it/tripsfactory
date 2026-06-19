import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AdBanner extends StatelessWidget {
  final String imageUrl;
  final String? clickUrl;

  const AdBanner({super.key, required this.imageUrl, this.clickUrl});

  Future<void> _handleTap() async {
    if (clickUrl == null || clickUrl!.isEmpty) return;

    final uri = Uri.parse(clickUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height / 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl.trim().isEmpty
              ? Container(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 400,
                  maxWidthDiskCache: 800,
                  maxHeightDiskCache: 600,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    highlightColor: isDark
                        ? Colors.grey[700]!
                        : Colors.grey[100]!,
                    child: Container(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
