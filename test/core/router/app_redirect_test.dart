import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/router/app_redirect.dart';
import 'package:tripship/features/profile/data/profile_model.dart';

void main() {
  group('computeRedirect', () {
    test('not logged in -> / redirects to /login', () {
      expect(
        computeRedirect(
          location: '/',
          isLoggedIn: false,
          onboardingSeen: true,
          updateRequired: false,
          profile: null,
        ),
        '/login',
      );
    });

    test('not logged in on /profile redirects to /login', () {
      expect(
        computeRedirect(
          location: '/profile',
          isLoggedIn: false,
          onboardingSeen: true,
          updateRequired: false,
          profile: null,
        ),
        '/login',
      );
    });

    test('logged in not suspended stays on /', () {
      expect(
        computeRedirect(
          location: '/',
          isLoggedIn: true,
          onboardingSeen: true,
          updateRequired: false,
          profile: const Profile(id: 'u1', fullName: 'User', isSuspended: false),
        ),
        isNull,
      );
    });

    test('logged in but suspended -> / redirects to /suspended', () {
      expect(
        computeRedirect(
          location: '/',
          isLoggedIn: true,
          onboardingSeen: true,
          updateRequired: false,
          profile: const Profile(id: 'u1', fullName: 'User', isSuspended: true),
        ),
        '/suspended',
      );
    });

    test('on /suspended with suspended profile stays', () {
      expect(
        computeRedirect(
          location: '/suspended',
          isLoggedIn: true,
          onboardingSeen: true,
          updateRequired: false,
          profile: const Profile(id: 'u1', fullName: 'User', isSuspended: true),
        ),
        isNull,
      );
    });

    test('on /suspended with non-suspended profile redirects to /', () {
      expect(
        computeRedirect(
          location: '/suspended',
          isLoggedIn: true,
          onboardingSeen: true,
          updateRequired: false,
          profile: const Profile(id: 'u1', fullName: 'User', isSuspended: false),
        ),
        '/',
      );
    });

    test('onboarding not seen redirects to /onboarding', () {
      expect(
        computeRedirect(
          location: '/',
          isLoggedIn: false,
          onboardingSeen: false,
          updateRequired: false,
          profile: null,
        ),
        '/onboarding',
      );
    });

    test('update required redirects to /force-update', () {
      expect(
        computeRedirect(
          location: '/',
          isLoggedIn: true,
          onboardingSeen: true,
          updateRequired: true,
          profile: const Profile(id: 'u1', fullName: 'User', isSuspended: false),
        ),
        '/force-update',
      );
    });

    test('on /login when logged in redirects to /', () {
      expect(
        computeRedirect(
          location: '/login',
          isLoggedIn: true,
          onboardingSeen: true,
          updateRequired: false,
          profile: null,
        ),
        '/',
      );
    });
  });
}
