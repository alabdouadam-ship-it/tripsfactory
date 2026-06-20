import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/core/services/app_config_service.dart';
import 'package:tripsfactory/core/theme/tripsfactory_motion_tokens.dart';
import 'package:tripsfactory/core/widgets/force_update_screen.dart';
import 'package:tripsfactory/core/widgets/app_closed_screen.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/features/auth/presentation/login_screen.dart';
import 'package:tripsfactory/features/auth/presentation/forgot_password_screen.dart';
import 'package:tripsfactory/features/auth/presentation/reset_password_screen.dart';
import 'package:tripsfactory/features/auth/presentation/signup_screen.dart';
import 'package:tripsfactory/features/auth/presentation/otp_verification_screen.dart';
import 'package:tripsfactory/features/bookings/presentation/my_requests_screen.dart';
import 'package:tripsfactory/features/chat/presentation/chat_screen.dart';
import 'package:tripsfactory/features/driver_registration/presentation/driver_registration_screen.dart';
import 'package:tripsfactory/features/profile/presentation/driver_profile_screen.dart';
import 'package:tripsfactory/features/profile/presentation/profile_screen.dart';
import 'package:tripsfactory/features/profile/presentation/ratings_detail_screen.dart';
import 'package:tripsfactory/features/profile/presentation/documents_screen.dart'
    as tripsfactory_documents;
import 'package:tripsfactory/features/settings/presentation/settings_screen.dart';
import 'package:tripsfactory/features/safety/presentation/blocked_users_screen.dart';
import 'package:tripsfactory/features/support/presentation/support_screen.dart';
import 'package:tripsfactory/features/support/presentation/support_chat_screen.dart';
import 'package:tripsfactory/features/support/data/support_service.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';
import 'package:tripsfactory/features/trips/presentation/my_trips_screen.dart';
import 'package:tripsfactory/features/trips/presentation/my_alerts_screen.dart';
import 'package:tripsfactory/features/trips/presentation/post_trip_screen.dart';
import 'package:tripsfactory/features/trips/presentation/trip_details_screen.dart';
import 'package:tripsfactory/core/router/app_redirect.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';
import 'package:tripsfactory/core/widgets/suspension_screen.dart';
import 'package:tripsfactory/features/home/presentation/notifications_screen.dart';
import 'package:tripsfactory/features/onboarding/presentation/onboarding_screen.dart';
import 'package:tripsfactory/home_screen.dart';
import 'package:tripsfactory/features/splash/presentation/splash_screen.dart';
import 'package:tripsfactory/core/config/app_routes.dart';

/// Route paths use kebab-case (e.g. /my-alerts, /trip-details).
/// Add new routes here and keep redirect logic in sync with auth/onboarding.

/// Premium route transition: 220ms fade + 10px upward slide.
CustomTransitionPage<T> _fadeUpPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: TripsFactoryMotionTokens.full, // 220ms
    reverseTransitionDuration: TripsFactoryMotionTokens.mid, // 180ms back
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: TripsFactoryMotionTokens.curveOut,
      );
      // 10px upward offset — subtle, purposeful
      final slide =
          Tween<Offset>(
            begin: const Offset(0.0, 0.04),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: TripsFactoryMotionTokens.curveOut,
            ),
          );

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// RouterNotifier encapsulates the listenable state that triggers router redirects.
/// By using refreshListenable, we avoid recreating the GoRouter instance
/// which was causing the "double splash" effect.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to all providers that affect redirection
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(appConfigProvider, (_, _) => notifyListeners());
    _ref.listen(currentUserProfileProvider, (_, _) => notifyListeners());
    // NOTE: preferencesServiceProvider intentionally NOT listened — it fires on
    // every cache write which re-triggers the expensive async redirect. The
    // onboardingSeen flag is read directly inside the redirect callback.
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const SignupScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.support,
        pageBuilder: (context, state) {
          final showNewTicket =
              (state.extra as Map<String, dynamic>?)?['showNewTicket']
                  as bool? ??
              false;
          final focusTicketId =
              (state.extra as Map<String, dynamic>?)?['focusTicketId']
                  as String?;
          return _fadeUpPage(
            state: state,
            child: SupportScreen(
              showNewTicket: showNewTicket,
              focusTicketId: focusTicketId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.documents,
        pageBuilder: (context, state) => _fadeUpPage(
          state: state,
          child: const tripsfactory_documents.DocumentsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        pageBuilder: (context, state) {
          final phone = state.extra is String
              ? state.extra as String
              : state.uri.queryParameters['phone'] ?? '';
          if (phone.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.login);
            });
            return _fadeUpPage(state: state, child: const SizedBox.shrink());
          }
          return _fadeUpPage(
            state: state,
            child: OtpVerificationScreen(phone: phone),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.postTrip,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _fadeUpPage(
            state: state,
            child: extra is Trip
                ? PostTripScreen(initialTrip: extra)
                : PostTripScreen(transportMode: extra as String?),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.travelerRegistration,
        pageBuilder: (context, state) {
          final isUpgrade = state.extra as bool? ?? false;
          return _fadeUpPage(
            state: state,
            child: TravelerRegistrationScreen(isUpgrade: isUpgrade),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myTrips,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const MyTripsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myAlerts,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const MyAlertsScreen()),
      ),
      GoRoute(
        path: AppRoutes.tripDetails,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final trip = extra is Trip
              ? extra
              : (extra is Map<String, dynamic> ? Trip.fromJson(extra) : null);
          final tripId = state.uri.queryParameters['id'] ?? trip?.id;
          return _fadeUpPage(
            state: state,
            child: TripDetailsScreen(trip: trip, tripId: tripId),
          );
        },
      ),
      GoRoute(
        path: '/trip/:id',
        redirect: (context, state) =>
            '${AppRoutes.tripDetails}?id=${state.pathParameters['id']}',
      ),
      GoRoute(
        path: AppRoutes.myRequests,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const MyRequestsScreen()),
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) {
          final e = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          if (e == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.home);
            });
            return _fadeUpPage(state: state, child: const SizedBox.shrink());
          }
          return _fadeUpPage(
            state: state,
            child: ChatScreen(
              bookingId: e['bookingId'] as String?,
              tripId: e['tripId'] as String?,
              driverId: e['driverId'] as String?,
              otherUserName: e['otherUserName'] as String? ?? '',
              otherUserId: e['otherUserId'] as String? ?? 'unknown',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.travelerProfile,
        pageBuilder: (context, state) {
          final e = state.extra;
          if (e == null || e is! Map<String, dynamic>) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.home);
            });
            return _fadeUpPage(state: state, child: const SizedBox.shrink());
          }
          return _fadeUpPage(
            state: state,
            child: PublicProfileScreen(
              userId: e['driverId'] as String,
              userName: e['driverName'] as String,
              role: e['role'] as String? ?? 'driver',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ratingsDetail,
        pageBuilder: (context, state) {
          final e = state.extra;
          if (e == null || e is! Map<String, dynamic>) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.home);
            });
            return _fadeUpPage(state: state, child: const SizedBox.shrink());
          }
          return _fadeUpPage(
            state: state,
            child: RatingsDetailScreen(
              userId: e['userId'] as String,
              isClient: e['isClient'] as bool,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const ResetPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetCallback,
        redirect: (context, state) => AppRoutes.resetPassword,
      ),
      GoRoute(
        path: AppRoutes.suspended,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const SuspensionScreen()),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        pageBuilder: (context, state) =>
            _fadeUpPage(state: state, child: const BlockedUsersScreen()),
      ),
      GoRoute(
        path: AppRoutes.forceUpdate,
        pageBuilder: (context, state) => _fadeUpPage(
          state: state,
          child: ForceUpdateScreen(message: state.extra as String?),
        ),
      ),
      GoRoute(
        path: AppRoutes.appClosed,
        pageBuilder: (context, state) => _fadeUpPage(
          state: state,
          child: const AppClosedScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.supportChat,
        pageBuilder: (context, state) {
          final ticket = state.extra as SupportTicket?;
          if (ticket == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.support);
            });
            return _fadeUpPage(state: state, child: const SizedBox.shrink());
          }
          return _fadeUpPage(
            state: state,
            child: SupportChatScreen(ticket: ticket),
          );
        },
      ),
    ],
    redirect: (context, state) async {
      final location = state.uri.toString();

      // Read current states via ref.read (triggered by refreshListenable)
      final authState = ref.read(authStateProvider);
      final config = ref.read(appConfigProvider);
      final profile = ref.read(currentUserProfileProvider);
      final prefs = ref.read(preferencesServiceProvider);

      final onboardingSeen = await prefs.getBool('onboarding_seen') ?? false;

      return computeRedirect(
        location: location,
        isLoggedIn: authState.value?.session != null,
        onboardingSeen: onboardingSeen,
        updateRequired: config.valueOrNull?.updateRequired ?? false,
        appOpen: config.valueOrNull?.appOpen ?? true,
        profile: profile.valueOrNull,
      );
    },
  );
});
