import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Empty State Widget - يستخدم عند عدم وجود بيانات
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final String?
  onSecondaryActionMessage; // New parameter to show text above secondary action
  final VoidCallback? onSecondaryActionPressed;
  final String? secondaryActionLabel;
  final VoidCallback? onTertiaryActionPressed;
  final String? tertiaryActionLabel;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onActionPressed,
    this.actionLabel,
    this.onSecondaryActionMessage,
    this.onSecondaryActionPressed,
    this.secondaryActionLabel,
    this.onTertiaryActionPressed,
    this.tertiaryActionLabel,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon with softer background
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      icon,
                      size: 56,
                      color: theme.hintColor.withValues(alpha: 0.4),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Text(
                title,
                style: textTheme.titleMedium?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),

              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (onActionPressed != null && actionLabel != null) ...[
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onActionPressed!();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(actionLabel!),
                  ),
                ),
              ],

              if (onSecondaryActionPressed != null &&
                  secondaryActionLabel != null) ...[
                const SizedBox(height: 16),
                if (onSecondaryActionMessage != null) ...[
                  Text(
                    onSecondaryActionMessage!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSecondaryActionPressed!();
                    },
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      size: 20,
                    ),
                    label: Text(secondaryActionLabel!),
                  ),
                ),
              ],

              if (onTertiaryActionPressed != null &&
                  tertiaryActionLabel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onTertiaryActionPressed!();
                  },
                  child: Text(
                    tertiaryActionLabel!,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
