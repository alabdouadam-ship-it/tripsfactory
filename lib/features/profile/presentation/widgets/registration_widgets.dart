import 'package:flutter/material.dart';

class RegistrationUploadButton extends StatelessWidget {
  final String label;
  final String? url;
  final VoidCallback onTap;
  final double height;

  const RegistrationUploadButton({
    super.key,
    required this.label,
    required this.url,
    required this.onTap,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUploaded = url != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUploaded
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          border: Border.all(
            color: isUploaded
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file_outlined,
              color: isUploaded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: height * 0.32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isUploaded
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isUploaded ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
