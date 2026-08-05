import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/l10n/localization_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to English', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider), AppLocale.en);
    });

    test('setLocale updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(AppLocale.fr);

      expect(container.read(localeProvider), AppLocale.fr);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'fr');
    });

    test('loadLocale restores saved locale over device language', () async {
      SharedPreferences.setMockInitialValues({'locale': 'fr'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(localeProvider.notifier)
          .loadLocale();

      expect(container.read(localeProvider), AppLocale.fr);
    });

    test('loadLocale falls back to French device language', () async {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith(
            (ref) => LocalizationNotifier(deviceLanguage: 'fr'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(localeProvider.notifier)
          .loadLocale();

      expect(container.read(localeProvider), AppLocale.fr);
    });

    test('loadLocale falls back to English device language', () async {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith(
            (ref) => LocalizationNotifier(deviceLanguage: 'en'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(localeProvider.notifier)
          .loadLocale();

      expect(container.read(localeProvider), AppLocale.en);
    });
  });
}
