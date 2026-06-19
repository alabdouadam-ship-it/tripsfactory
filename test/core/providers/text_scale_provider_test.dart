import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/providers/text_scale_provider.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late PreferencesService prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('TextScaleNotifier starts with normal', () async {
    prefs = PreferencesService(await SharedPreferences.getInstance());

    final container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(textScaleProvider), TextScaleOption.normal);
  });

  test('TextScaleNotifier setScale updates state', () async {
    prefs = PreferencesService(await SharedPreferences.getInstance());

    final container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container
        .read(textScaleProvider.notifier)
        .setScale(TextScaleOption.large);
    expect(container.read(textScaleProvider), TextScaleOption.large);
    expect(container.read(textScaleProvider).scale, 1.2);
  });
}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
