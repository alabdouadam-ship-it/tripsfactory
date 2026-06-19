import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/config/demo_config.dart';
import 'package:tripship/core/demo/demo_mode.dart';
import 'package:tripship/core/services/notification_service.dart';

/// Initializes all app dependencies (env, Supabase, Firebase, notifications, preferences).
Future<SharedPreferences> bootstrap() async {
  final prefs = await bootstrapCore();
  await bootstrapPostLaunchServices();
  return prefs;
}

Future<SharedPreferences> bootstrapCore() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (DemoConfig.enabled) {
    // Demo mode: no real backend. Initialize Supabase against placeholder
    // values so the client singleton exists, then install a fake offline
    // session. No `.env` or Firebase is required.
    await Supabase.initialize(
      url: DemoConfig.placeholderSupabaseUrl,
      anonKey: DemoConfig.placeholderSupabaseAnonKey,
    );
    await initDemoSession();
    final demoPrefs = await SharedPreferences.getInstance();
    // Skip onboarding so the demo lands directly on the populated Home.
    await demoPrefs.setBool('onboarding_seen', true);
    return demoPrefs;
  }

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (!e.toString().contains('duplicate app')) rethrow;
  }

  final prefs = await SharedPreferences.getInstance();
  return prefs;
}

Future<void> bootstrapPostLaunchServices() async {
  // Push/notifications require a real backend; skip entirely in demo mode.
  if (DemoConfig.enabled) return;
  final notificationService = NotificationService(Supabase.instance.client);
  await notificationService.initialize();
}
