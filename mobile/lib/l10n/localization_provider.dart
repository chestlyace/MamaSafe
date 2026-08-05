import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { en, fr }

class LocalizationNotifier extends StateNotifier<AppLocale> {
  LocalizationNotifier({String? deviceLanguage})
      : _deviceLanguage = deviceLanguage,
        super(AppLocale.en);

  final String? _deviceLanguage;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale');
    if (saved != null) {
      state = saved == 'fr' ? AppLocale.fr : AppLocale.en;
      return;
    }
    final deviceLanguage = _deviceLanguage ??
        PlatformDispatcher.instance.locale.languageCode;
    state = deviceLanguage == 'fr' ? AppLocale.fr : AppLocale.en;
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.name);
  }
}

final localeProvider =
    StateNotifierProvider<LocalizationNotifier, AppLocale>((ref) {
  return LocalizationNotifier();
});
