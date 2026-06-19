import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/core/router/app_redirect.dart';
import 'package:tripship/core/config/brand_config.dart';
import 'package:tripship/core/services/app_config_service.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:tripship/features/auth/data/auth_service.dart';

/// A premium animated splash screen shown while app services initialize.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late final Timer _minTimer;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    // Ensure the splash shows for at least 2.5 seconds
    _minTimer = Timer(const Duration(milliseconds: 2500), () {
      _minTimeElapsed = true;
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _minTimer.cancel();
    super.dispose();
  }

  void _tryNavigate() {
    if (_navigated || !_minTimeElapsed || !mounted) return;

    final authState = ref.read(authStateProvider);
    final configAsync = ref.read(appConfigProvider);
    final profileAsync = ref.read(currentUserProfileProvider);
    final prefs = ref.read(preferencesServiceProvider);

    // Wait until auth state resolves
    if (authState.isLoading) return;

    final isLoggedIn = authState.value?.session != null;
    final updateRequired = configAsync.valueOrNull?.updateRequired ?? false;

    // Read onboarding flag synchronously from preferences
    prefs.getBool('onboarding_seen').then((onboardingSeen) {
      if (!mounted || _navigated) return;

      final target = computeRedirect(
        location: '/',
        isLoggedIn: isLoggedIn,
        onboardingSeen: onboardingSeen ?? false,
        updateRequired: updateRequired,
        profile: profileAsync.value,
      );

      _navigated = true;
      context.go(target ?? '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to providers and try to navigate when they resolve
    ref.listen(authStateProvider, (_, _) => _tryNavigate());
    ref.listen(appConfigProvider, (_, _) => _tryNavigate());
    ref.listen(currentUserProfileProvider, (_, _) => _tryNavigate());

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Build a premium gradient from the theme's primary color
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF0A0E21),
              colorScheme.primary.withValues(alpha: 0.15),
              const Color(0xFF0A0E21),
            ]
          : [
              const Color(0xFF0F1B3D),
              colorScheme.primary.withValues(alpha: 0.85),
              const Color(0xFF162044),
            ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // --- Glow ring behind the icon ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow pulse — scale only, no fade (avoids Impeller opacity bug)
                        Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.9, end: 1.05, duration: 2000.ms),

                        // App Icon — RepaintBoundary isolates compositing for Impeller
                        RepaintBoundary(
                          child:
                              Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.asset(
                                        BrandConfig.logoAsset,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .scaleXY(
                                    begin: 0.5,
                                    end: 1.0,
                                    duration: 800.ms,
                                    curve: Curves.easeOutBack,
                                  )
                                  .fade(duration: 600.ms),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // --- App Name ---
                    Text(
                          BrandConfig.brandName,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fade(delay: 400.ms, duration: 600.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 8),

                    // --- Tagline ---
                    Text(
                          BrandConfig.splashTagline,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        )
                        .animate()
                        .fade(delay: 800.ms, duration: 600.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ),

                    const Spacer(flex: 2),

                    // --- Progress Indicator ---
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ).animate().fade(delay: 1200.ms, duration: 500.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
