import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';

class SuspensionScreen extends ConsumerWidget {
  const SuspensionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Calm amber/slate, not alarming red
    final accentColor = const Color(
      0xFFB45309,
    ); // Amber 700 — serious, not alarming
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFFAFAF9);
    final surfaceColor = isDark ? const Color(0xFF292524) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Consumer(
              builder: (context, ref, child) {
                final profile = ref.watch(currentUserProfileProvider).value;
                final reason = profile?.suspensionReason;
                final isBlocked = profile?.isBlocked ?? false;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Administrative icon — no alarming full red circle
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isBlocked
                            ? Icons.block_flipped
                            : Icons.lock_person_outlined,
                        size: 48,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Structured title — decisive and calm
                    Text(
                      key: const Key('error_title'),
                      isBlocked
                          ? l10n.accountBlocked
                          : l10n.accountSuspendedTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      key: const Key('error_explanation'),
                      reason ??
                          (isBlocked
                              ? l10n.accountBlockedMessage
                              : l10n.accountSuspendedMessage),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (!isBlocked) ...[
                      const SizedBox(height: 8),
                      // Reference notice
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.suspensionErrorNotice,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.5,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contact support — primary action
                      SizedBox(
                        key: const Key('error_next_step_cta'),
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/support');
                          },
                          icon: const Icon(
                            Icons.support_agent_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.contactSupport),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            foregroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sign out — secondary, neutral
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () =>
                              ref.read(authServiceProvider).signOut(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: theme.textTheme.bodySmall?.color,
                          ),
                          child: Text(l10n.logout),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
