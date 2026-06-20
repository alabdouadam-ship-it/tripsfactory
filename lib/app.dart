import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/config/app_routes.dart';
import 'package:tripship/core/config/brand_config.dart';
import 'package:tripship/core/config/demo_config.dart';
import 'package:tripship/core/config/font_config.dart';
import 'package:tripship/core/config/localization_config.dart';
import 'package:tripship/core/providers/locale_provider.dart';
import 'package:tripship/core/providers/text_scale_provider.dart';
import 'package:tripship/core/router/app_router.dart';
import 'package:tripship/core/services/navigation_service.dart';
import 'package:tripship/core/theme/app_theme.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/workers/sync_worker.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/features/auth/data/auth_service.dart';

class TripShipApp extends ConsumerStatefulWidget {
  const TripShipApp({super.key});

  @override
  ConsumerState<TripShipApp> createState() => _TripShipAppState();
}

class _TripShipAppState extends ConsumerState<TripShipApp>
    with WidgetsBindingObserver {
  late final AppLinks _appLinks = AppLinks();
  String? _lastHandledUri;
  DateTime? _lastHandledAt;
  DateTime? _lastResumeRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force SyncWorker instantiation — non-disposing provider stays alive
      // for the full app session without needing to be watched in build().
      ref.read(syncWorkerProvider);
      _handleInitialLink();
      ref.read(navigationServiceProvider).setupNotificationNavigation();
    });
    _appLinks.uriLinkStream.listen((uri) {
      if (mounted) _navigateFromUri(uri);
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the cached profile when the app returns to the foreground so
    // admin-side changes (driver approval, suspension) show up
    // without a restart. Throttled: quick app switches don't re-fetch.
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastResumeRefreshAt != null &&
        now.difference(_lastResumeRefreshAt!).inSeconds < 30) {
      return;
    }
    _lastResumeRefreshAt = now;
    ref.invalidate(currentUserProfileProvider);
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null && mounted) _navigateFromUri(uri);
    } catch (e, stackTrace) {
      StructuredLogger.error('TripShipApp', 'Deep link error: $e', e, stackTrace);
    }
  }

  void _navigateFromUri(Uri uri) {
    // Some Android/iOS setups deliver the same deep-link twice:
    // - once via getInitialLink()
    // - once via uriLinkStream
    // Processing both can trigger duplicate route transitions in one frame,
    // which leads to Overlay GlobalKey collisions.
    final now = DateTime.now();
    final uriText = uri.toString();
    final handledRecently =
        _lastHandledUri == uriText &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!).inSeconds < 2;
    if (handledRecently) return;
    _lastHandledUri = uriText;
    _lastHandledAt = now;

    // Supabase auth callbacks: route from the deep link itself.
    // Keeping this in one place avoids duplicate navigation from both
    // onAuthStateChange and deep-link listeners.
    if (uri.scheme == BrandConfig.authScheme) {
      if (uri.host == 'reset-callback') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final router = ref.read(routerProvider);
          final current =
              router.routerDelegate.currentConfiguration.uri.toString();
          if (current != AppRoutes.resetPassword) {
            router.go(AppRoutes.resetPassword);
          }
        });
      } else if (uri.host == 'login-callback') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final router = ref.read(routerProvider);
          final current =
              router.routerDelegate.currentConfiguration.uri.toString();
          if (current != AppRoutes.home) {
            router.go(AppRoutes.home);
          }
        });
      }
      return;
    }

    if (uri.scheme == BrandConfig.contentScheme) {
      if (uri.host == 'trip' && uri.pathSegments.isNotEmpty) {
        final tripId = uri.pathSegments.first;
        ref
            .read(routerProvider)
            .push(
              Uri(
                path: AppRoutes.tripDetails,
                queryParameters: {'id': tripId},
              ).toString(),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final scale = ref.watch(textScaleProvider).scale;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(
          themeMode,
          fontFamily: FontConfig.resolve(locale, themeMode),
        ),
        routerConfig: router,
        locale: locale,
        builder: DemoConfig.enabled
            ? (context, child) => Banner(
                  message: 'DEMO',
                  location: BannerLocation.topEnd,
                  color: Colors.deepOrange,
                  child: child ?? const SizedBox.shrink(),
                )
            : null,
        supportedLocales: LocalizationConfig.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
