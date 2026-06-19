import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/services/preferences_service.dart';

/// Text scale factors for accessibility.
enum TextScaleOption {
  small(0.85),
  normal(1.0),
  large(1.2),
  extraLarge(1.4);

  const TextScaleOption(this.scale);
  final double scale;
}

class TextScaleNotifier extends StateNotifier<TextScaleOption> {
  final PreferencesService _prefs;
  static const String _key = 'text_scale';

  TextScaleNotifier(this._prefs) : super(TextScaleOption.normal) {
    final saved = _prefs.getStringSync(_key);
    if (saved != null) {
      state = TextScaleOption.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => TextScaleOption.normal,
      );
    }
  }

  Future<void> setScale(TextScaleOption opt) async {
    state = opt;
    await _prefs.setString(_key, opt.name);
  }
}

final textScaleProvider = StateNotifierProvider<TextScaleNotifier, TextScaleOption>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return TextScaleNotifier(prefs);
});
