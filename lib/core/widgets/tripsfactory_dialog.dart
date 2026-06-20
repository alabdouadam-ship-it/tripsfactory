import 'package:flutter/material.dart';
import 'package:tripsfactory/core/theme/tripsfactory_design_tokens.dart';
import 'package:tripsfactory/core/theme/tripsfactory_motion_tokens.dart';

class TripsFactoryDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final IconData? icon;

  const TripsFactoryDialog({
    super.key,
    required this.title,
    required this.content,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
    this.icon,
  });

  /// Shows the dialog with a premium 180ms scale+fade entry animation.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    required String cancelLabel,
    required String confirmLabel,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: TripsFactoryMotionTokens.mid, // 180ms
      pageBuilder: (context, animation, secondaryAnimation) => TripsFactoryDialog(
        title: title,
        content: content,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onCancel: onCancel,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
        icon: icon,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: TripsFactoryMotionTokens.curveInOut,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusLarge,
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          shape: BoxShape.rectangle,
          borderRadius: TripsFactoryDesignTokens.borderRadiusLarge,
          boxShadow: TripsFactoryDesignTokens.shadowLevel2(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: confirmColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: confirmColor),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.8,
                ),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
