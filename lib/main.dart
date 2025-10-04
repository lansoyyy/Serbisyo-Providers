import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hanap_raket/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hanap_raket/screens/providers/provider_main_screen.dart';
import 'package:hanap_raket/screens/providers/auth/provider_login_screen.dart';
import 'package:hanap_raket/screens/providers/auth/provider_signup_screen.dart';
import 'package:hanap_raket/screens/providers/auth/provider_application_processing_screen.dart';
import 'package:hanap_raket/screens/force_update_screen.dart';
import 'package:hanap_raket/screens/admin/firebase_init_screen.dart';
import 'package:hanap_raket/screens/splash_screen.dart';
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
  bool _isCheckingAuth = true;
  bool _showSplash = true;
  Map<String, dynamic>? _updateInfo;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // Hide splash screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    // Check for updates and authentication status in parallel
    final results = await Future.wait([
      VersionService.checkForceUpdate(),
      _checkAuthStatus(),
    ]);

    setState(() {
      _updateInfo = results[0] as Map<String, dynamic>?;
      _isCheckingUpdate = false;
      _isCheckingAuth = false;
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check if user is logged in according to preferences
      if (PreferenceService.isLoggedIn()) {
        final userId = PreferenceService.getUserId();
        final username = PreferenceService.getUsername();

        if (userId != null && username != null) {
          // Check if user exists in Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('providers')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final providerData = userDoc.data()!;
            final applicationStatus =
                providerData['applicationStatus'] as String?;

            // Set initial route based on application status
            switch (applicationStatus) {
              case 'pending':
                _initialRoute = '/provider-application-processing';
                break;
              case 'approved':
                _initialRoute = '/provider-main';
                break;
              case 'rejected':
                // Clear login info for rejected users
                await PreferenceService.clearUserLoginInfo();
                _initialRoute = '/provider-login';
                break;
              default:
                _initialRoute = '/provider-main';
            }
          } else {
            // User is not a provider, clear login info
            await PreferenceService.clearUserLoginInfo();
            _initialRoute = '/provider-login';
          }
        } else {
          // Incomplete login info, clear preferences
          await PreferenceService.clearUserLoginInfo();
          _initialRoute = '/provider-login';
        }
      } else {
        // User is not logged in according to preferences
        _initialRoute = '/provider-login';
      }
    } catch (e) {
      // If there's any error during auth check, default to login screen
      _initialRoute = '/provider-login';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      );
    }

    // Show loading while checking for updates and authentication
    if (_isCheckingUpdate || _isCheckingAuth) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontFamily: 'Medium',
                  ),
                ),
              ],
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

    // Normal app flow with dynamic initial route
    return GetMaterialApp(
      title: 'Serbisyo - Providers',
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
      initialRoute: _initialRoute ?? '/provider-login',
      getPages: [
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
