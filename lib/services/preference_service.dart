import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'user_username';
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

  static String? getUsername() {
    return _prefs?.getString(_keyUsername);
  }

  static Future<void> setUsername(String username) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
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
    required String username,
    required bool rememberMe,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_keyIsLoggedIn, true),
      prefs.setString(_keyUserId, userId),
      prefs.setString(_keyUsername, username),
      prefs.setBool(_keyRememberMe, rememberMe),
    ]);
  }

  // Clear user login information
  static Future<void> clearUserLoginInfo() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyIsLoggedIn),
      prefs.remove(_keyUserId),
      prefs.remove(_keyUsername),
    ]);
  }
}
