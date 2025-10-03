import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyOnboardingSeen = 'onboarding_seen';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool hasSeenOnboarding() {
    return _prefs?.getBool(_keyOnboardingSeen) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }

  static Future<void> clearOnboardingPreference() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, false);
  }
}
