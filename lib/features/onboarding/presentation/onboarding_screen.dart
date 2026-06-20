import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.setBool('onboarding_seen', true);
      StructuredLogger.info(
        'OnboardingScreen',
        'User completed onboarding',
      );
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e, st) {
      StructuredLogger.error(
        'OnboardingScreen',
        'Failed to save onboarding state',
        e,
        st,
      );
      if (mounted) {
        context.go(AppRoutes.home); // proceed anyway
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final pages = [
      _OnboardingPage(
        icon: Icons.rocket_launch_rounded,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        title: loc.appTitle,
        subtitle: loc.appTagline,
        description: loc.onboardingSubtitle3,
        isRTL: isRTL,
      ),
      _OnboardingPage(
        icon: Icons.local_shipping_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        title: loc.postTrip,
        subtitle: loc.onboardingSubtitle2,
        description: loc.onboardingEarnMoney,
        isRTL: isRTL,
      ),
      _OnboardingPage(
        icon: Icons.inventory_2_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade600,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        title: loc.postPackage,
        subtitle: loc.onboardingSubtitle1,
        description: loc.onboardingSendPackages,
        isRTL: isRTL,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentPage == 0
                    ? [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.surface,
                      ]
                    : _currentPage == 1
                        ? [
                            Colors.blue.shade50,
                            theme.colorScheme.surface,
                          ]
                        : [
                            Colors.orange.shade50,
                            theme.colorScheme.surface,
                          ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          loc.skip,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: pages.length,
                    itemBuilder: (_, i) => pages[i],
                  ),
                ),

                // Bottom Navigation
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          // Back Button
                          if (_currentPage > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(loc.back),
                              ),
                            ),
                          if (_currentPage > 0) const SizedBox(width: 12),

                          // Next/Get Started Button
                          Expanded(
                            flex: _currentPage > 0 ? 1 : 1,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPage < pages.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _completeOnboarding();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 56),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _currentPage < pages.length - 1
                                          ? loc.next
                                          : loc.getStarted,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage < pages.length - 1
                                        ? (isRTL
                                            ? Icons.arrow_back_rounded
                                            : Icons.arrow_forward_rounded)
                                        : Icons.check_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final String description;
  final bool isRTL;

  const _OnboardingPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Animated Icon Container
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 100,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                )
                .fadeIn(),

            const SizedBox(height: 48),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 200))
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400))
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                ),

            const SizedBox(height: 24),

            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 600))
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                ),

            const SizedBox(height: 40),

            // Feature Pills
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeaturePill(
                  icon: Icons.verified_user_rounded,
                  label: loc.onboardingSecure,
                  gradient: gradient,
                ),
                _FeaturePill(
                  icon: Icons.flash_on_rounded,
                  label: loc.onboardingFast,
                  gradient: gradient,
                ),
                _FeaturePill(
                  icon: Icons.savings_rounded,
                  label: loc.onboardingAffordable,
                  gradient: gradient,
                ),
              ],
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 800))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 400),
                ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final gradientWithAlpha = LinearGradient(
      colors: gradient.colors
          .map((c) => c.withValues(alpha: c.a * 0.3))
          .toList(),
      begin: gradient is LinearGradient
          ? (gradient as LinearGradient).begin
          : Alignment.topLeft,
      end: gradient is LinearGradient
          ? (gradient as LinearGradient).end
          : Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradientWithAlpha,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: gradient.colors.first,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: gradient.colors.first,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

