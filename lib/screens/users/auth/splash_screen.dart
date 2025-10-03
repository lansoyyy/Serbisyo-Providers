import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/loading.indicator_widget.dart';
import '../../../services/preference_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Initialize animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    // Start animations sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start background animation immediately
    _backgroundController.forward();

    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Navigate to appropriate screen after animations complete
    await Future.delayed(const Duration(milliseconds: 2000));

    // 1) Auto-login if user is still authenticated (wait for initial auth state)
    final currentUser = await _resolveInitialUser();
    if (currentUser != null) {
      Get.offAllNamed('/main');
      return;
    }

    // 2) Onboarding gate (only if not logged in)
    final hasSeenOnboarding = PreferenceService.hasSeenOnboarding();
    if (!hasSeenOnboarding) {
      Get.offAllNamed('/onboarding');
      return;
    }

    // 3) Default to login
    Get.offAllNamed('/login');
  }

  // Attempts to resolve the initial Firebase user, waiting briefly for the
  // first auth state emission in case persistence restoration is still pending.
  Future<User?> _resolveInitialUser() async {
    try {
      final userNow = FirebaseAuth.instance.currentUser;
      if (userNow != null) return userNow;

      final userFromStream = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 2));
      return userFromStream;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primary
                      .withOpacity(0.05 * _backgroundAnimation.value),
                  AppColors.primary
                      .withOpacity(0.1 * _backgroundAnimation.value),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                _buildBackgroundParticles(),

                // Main content
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Enhanced Logo Section
                      _buildEnhancedLogo(),

                      const SizedBox(height: 50),

                      // Enhanced App Name and Tagline Section
                      _buildEnhancedText(),

                      const Spacer(flex: 2),

                      // Enhanced Loading Section
                      _buildEnhancedLoading(),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: ParticlePainter(
              animationValue: _particleAnimation.value,
              primaryColor: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value,
            child: Opacity(
              opacity: _logoOpacityAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background glow effect
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Main icon
                    const Icon(
                      FontAwesomeIcons.handshake,
                      size: 55,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlideAnimation,
          child: Opacity(
            opacity: _textOpacityAnimation.value,
            child: Column(
              children: [
                // Main app name with gradient text effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ).createShader(bounds),
                  child: TextWidget(
                    text: 'Serbisyo',
                    fontSize: 36,
                    fontFamily: 'Bold',
                    color: Colors.white,
                    letterSpacing: 2,
                    align: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                // Enhanced tagline
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextWidget(
                    text: 'Find Your Perfect Service',
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: AppColors.primary.withOpacity(0.8),
                    align: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Feature highlights
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureChip('Professional'),
                    const SizedBox(width: 8),
                    _buildFeatureChip('Reliable'),
                    const SizedBox(width: 8),
                    _buildFeatureChip('Fast'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextWidget(
        text: text,
        fontSize: 11,
        fontFamily: 'Bold',
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEnhancedLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          // Custom loading indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const LoadingIndicatorWidget(),
          ),
          const SizedBox(height: 24),
          // Loading text with animation
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              final dots = '.' * ((_particleAnimation.value * 3).floor() + 1);
              return TextWidget(
                text: 'Loading$dots',
                fontSize: 16,
                fontFamily: 'Medium',
                color: AppColors.primary.withOpacity(0.7),
                align: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 8),
          // Progress indicator
          Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _backgroundAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;

  ParticlePainter({
    required this.animationValue,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final xOffset = (size.width / 20 * i + animationValue * 50) % size.width;
      final yOffset =
          (size.height / 10 * (i % 10) + animationValue * 30) % size.height;
      final radius = 2.0 + (i % 3).toDouble();

      canvas.drawCircle(
        Offset(xOffset, yOffset),
        radius,
        paint..color = primaryColor.withOpacity(0.05 + (i % 3) * 0.02),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
