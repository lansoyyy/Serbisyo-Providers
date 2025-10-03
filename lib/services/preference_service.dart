import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyRememberMe = 'remember_me';
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

  // User authentication methods
  static bool isLoggedIn() {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  static String? getUserId() {
    return _prefs?.getString(_keyUserId);
  }

  static Future<void> setUserId(String userId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static String? getUserEmail() {
    return _prefs?.getString(_keyUserEmail);
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static bool isRememberMeEnabled() {
    return _prefs?.getBool(_keyRememberMe) ?? false;
  }

  static Future<void> setRememberMe(bool rememberMe) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  // Save user login information
  static Future<void> saveUserLoginInfo({
    required String userId,
    required String email,
    required bool rememberMe,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_keyIsLoggedIn, true),
      prefs.setString(_keyUserId, userId),
      prefs.setString(_keyUserEmail, email),
      prefs.setBool(_keyRememberMe, rememberMe),
    ]);
  }

  // Clear user login information
  static Future<void> clearUserLoginInfo() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyIsLoggedIn),
      prefs.remove(_keyUserId),
      prefs.remove(_keyUserEmail),
    ]);
  }
}
