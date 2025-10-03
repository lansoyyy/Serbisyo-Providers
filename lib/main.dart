import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hanap_raket/firebase_options.dart';
import 'package:hanap_raket/screens/users/main_screen.dart';
import 'package:hanap_raket/screens/users/auth/splash_screen.dart';
import 'package:hanap_raket/screens/users/auth/onboarding_screen.dart';
import 'package:hanap_raket/screens/users/auth/login_screen.dart';
import 'package:hanap_raket/screens/users/auth/signup_screen.dart';

import 'package:hanap_raket/screens/providers/provider_main_screen.dart';
import 'package:hanap_raket/screens/providers/auth/provider_login_screen.dart';
import 'package:hanap_raket/screens/providers/auth/provider_signup_screen.dart';
import 'package:hanap_raket/screens/providers/auth/provider_application_processing_screen.dart';
import 'package:hanap_raket/screens/force_update_screen.dart';
import 'package:hanap_raket/screens/admin/firebase_init_screen.dart';
import 'utils/colors.dart';
import 'services/preference_service.dart';
import 'services/version_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'click-6e2b3',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local preferences (e.g., onboarding flag)
  await PreferenceService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isCheckingUpdate = true;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await VersionService.checkForceUpdate();
    setState(() {
      _updateInfo = updateInfo;
      _isCheckingUpdate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking for updates
    if (_isCheckingUpdate) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    // Show force update screen if update is required
    if (_updateInfo != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ForceUpdateScreen(
          currentVersion: _updateInfo!['current_version'],
          latestVersion: _updateInfo!['latest_version'],
          changes: _updateInfo!['changes'],
          updateUrl: _updateInfo!['update_url'],
        ),
      );
    }

    // Normal app flow
    return GetMaterialApp(
      title: 'Serbisyo',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          error: AppColors.accent,
          onError: AppColors.onAccent,
          background: AppColors.background,
          onBackground: Colors.black,
          surface: AppColors.surface,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // initialRoute: '/provider-login',
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/main', page: () => const MainScreen()),
        GetPage(name: '/provider-main', page: () => const ProviderMainScreen()),
        GetPage(
            name: '/provider-login', page: () => const ProviderLoginScreen()),
        GetPage(
            name: '/provider-signup', page: () => const ProviderSignupScreen()),
        GetPage(
            name: '/provider-application-processing',
            page: () => const ProviderApplicationProcessingScreen()),
        GetPage(name: '/firebase-init', page: () => const FirebaseInitScreen()),
      ],
    );
  }
}
