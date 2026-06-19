import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/core/config/app_routes.dart';

/// Pure redirect logic for testing. Used by [app_router] to decide redirect path.
/// Parameters mirror what the router reads from providers.
String? computeRedirect({
  required String location,
  required bool isLoggedIn,
  required bool onboardingSeen,
  required bool updateRequired,
  bool appOpen = true,
  Profile? profile,
}) {
  // Splash screen always allowed — it handles its own navigation
  if (location == AppRoutes.splash) return null;

  // Global app-closed switch (driven by the admin console)
  final isAppClosedRoute = location == AppRoutes.appClosed;
  if (!appOpen) {
    if (!isAppClosedRoute) return AppRoutes.appClosed;
    return null;
  }
  if (isAppClosedRoute) return AppRoutes.home;

  final isUpdateRoute = location == AppRoutes.forceUpdate;
  if (updateRequired) {
    if (!isUpdateRoute) return AppRoutes.forceUpdate;
    return null;
  }
  if (isUpdateRoute) return AppRoutes.home;

  final isOnboardingRoute = location == AppRoutes.onboarding;
  if (!onboardingSeen && !isOnboardingRoute) return AppRoutes.onboarding;

  final isLoggingIn = location == AppRoutes.login;
  final isSigningUp = location == AppRoutes.signup;
  final isForgotPassword = location == AppRoutes.forgotPassword;
  final isResetting = location.startsWith(
    '/reset-',
  ); // Partial match needed for dynamic tokens
  final isSuspendedRoute = location == AppRoutes.suspended;

  // Auth routes intentionally bypass the onboarding check above.
  // Users must be able to reach login/signup even if onboarding hasn't been seen,
  // because the onboarding screen itself may navigate to them.
  if (isResetting || isLoggingIn || isSigningUp || isForgotPassword) {
    if (isLoggedIn && !isResetting) return AppRoutes.home;
    return null;
  }

  if (!isLoggedIn) {
    return AppRoutes.login;
  }

  if (profile != null && (profile.isSuspended || profile.isBlocked)) {
    if (isSuspendedRoute) return null;
    return AppRoutes.suspended;
  }

  if (isSuspendedRoute &&
      (profile == null || (!profile.isSuspended && !profile.isBlocked))) {
    return AppRoutes.home;
  }

  return null;
}
