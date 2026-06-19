import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/services/app_config_service.dart';

/// Shown when the admin console has flipped the global "app open" switch off.
/// Polls the configuration so that it auto-recovers when the admin re-opens
/// the app, without requiring the user to restart.
class AppClosedScreen extends ConsumerWidget {
  const AppClosedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);

    final localeIsArabic = Localizations.localeOf(context).languageCode == 'ar';
    final closedMessage = config.maybeWhen(
      data: (c) => localeIsArabic
          ? (c.closedMessageAr ?? c.closedMessage)
          : (c.closedMessage ?? c.closedMessageAr),
      orElse: () => null,
    );

    final title = localeIsArabic ? 'سنعود قريباً' : 'We will be right back';
    final defaultMessage = localeIsArabic
        ? 'التطبيق مغلق مؤقتاً للصيانة. يرجى المحاولة لاحقاً.'
        : 'The app is temporarily closed for maintenance. Please check back soon.';
    final retryLabel = localeIsArabic ? 'المحاولة مرة أخرى' : 'Try again';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                closedMessage ?? defaultMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => ref.invalidate(appConfigProvider),
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
