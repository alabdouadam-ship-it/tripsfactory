import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:tripship/core/utils/logger.dart';

final appReviewServiceProvider = Provider<AppReviewService>((ref) {
  return AppReviewService(ref.watch(preferencesServiceProvider));
});

/// Shows in-app review prompt after the user has used the app enough.
class AppReviewService {
  static const String _launchCountKey = 'app_launch_count';
  static const String _ratePromptShownKey = 'rate_prompt_shown';
  static const int _minLaunchesBeforePrompt = 5;

  final PreferencesService _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  AppReviewService(this._prefs);

  /// Call on app launch (e.g. from HomeScreen). Will show review prompt
  /// after [(_minLaunchesBeforePrompt)] launches, if not shown before.
  Future<void> maybeRequestReview() async {
    try {
      if (!await _inAppReview.isAvailable()) return;

      final shown = await _prefs.getBool(_ratePromptShownKey) ?? false;
      if (shown) return;

      final count = await _prefs.getInt(_launchCountKey) ?? 0;
      await _prefs.setInt(_launchCountKey, count + 1);

      if (count + 1 >= _minLaunchesBeforePrompt) {
        await _prefs.setBool(_ratePromptShownKey, true);
        await _inAppReview.requestReview();
      }
    } catch (e, st) {
      StructuredLogger.error(
        'AppReviewService',
        'maybeRequestReview error',
        e,
        st,
      );
    }
  }

  /// Open store listing (no quota). Use for "Rate us" button in settings.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e, st) {
      StructuredLogger.error(
        'AppReviewService',
        'openStoreListing error',
        e,
        st,
      );
    }
  }
}
