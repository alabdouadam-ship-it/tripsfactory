import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/theme/app_theme.dart';

/// Pumps a minimal app shell with localization and optional locale for conversion tests.
Future<void> pumpConversionWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override>? overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps a widget with app theme + localization for trust_ux tests.
Future<void> pumpTrustUxWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override>? overrides,
  bool rtl = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.getTheme(AppThemeMode.tripsfactoryLight),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: rtl
            ? Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(body: child),
              )
            : Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}
