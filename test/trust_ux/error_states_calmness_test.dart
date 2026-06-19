import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/widgets/suspension_screen.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('Calm error and edge-case UI', () {
    testWidgets('SuspensionScreen has error_title (suspended title)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) => null),
            authServiceProvider.overrideWith((ref) => MockAuthService()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SuspensionScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('error_title')), findsOneWidget);
    });

    testWidgets('SuspensionScreen has error_explanation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) => null),
            authServiceProvider.overrideWith((ref) => MockAuthService()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SuspensionScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('error_explanation')), findsOneWidget);
    });

    testWidgets('SuspensionScreen has error_next_step_cta (contact support)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) => null),
            authServiceProvider.overrideWith((ref) => MockAuthService()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SuspensionScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('error_next_step_cta')), findsOneWidget);
    });
  });
}
