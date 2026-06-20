import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tripsfactory/app.dart';
import 'package:tripsfactory/app_bootstrap.dart';
import 'package:tripsfactory/core/config/demo_config.dart';
import 'package:tripsfactory/core/demo/demo_mode.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';
import 'package:tripsfactory/core/services/offline_sync_service.dart';

import 'dart:async';
import 'dart:ui';
import 'package:tripsfactory/core/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background threads safely use StructuredLogger as it only wraps print statements.
  StructuredLogger.info(
    'FirebaseMessaging',
    'Handling a background message: ${message.messageId}',
  );
}

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final prefs = await bootstrapCore();

      if (!DemoConfig.enabled) {
        try {
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
        } catch (e) {
          StructuredLogger.error(
            'FirebaseMessaging',
            'Failed to set bg handler',
            e,
          );
        }
      }

      final preferencesService = PreferencesService(prefs);
      final offlineSyncService = OfflineSyncService(prefs);

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        StructuredLogger.error(
          'FlutterError',
          details.exceptionAsString(),
          details.exception,
          details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        StructuredLogger.fatal(
          'PlatformDispatcher',
          'Unhandled engine error',
          error,
          stack,
        );
        return true;
      };

      runApp(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            offlineSyncServiceProvider.overrideWithValue(offlineSyncService),
            if (DemoConfig.enabled) ...demoProviderOverrides(),
          ],
          child: const TripsFactoryApp(),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(bootstrapPostLaunchServices());
      });
    },
    (error, stack) {
      StructuredLogger.fatal(
        'ZonedGuarded',
        'Uncaught runtime error',
        error,
        stack,
      );
    },
  );
}
