import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingKey = 'onboarding_complete';

Future<bool> _isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey) ?? false;
}

Future<void> _setOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingKey, true);
}

final onboardingDoneProvider = FutureProvider<bool>((ref) {
  return _isOnboardingDone();
});

final completeOnboardingProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await _setOnboardingDone();
    ref.invalidate(onboardingDoneProvider);
  };
});
