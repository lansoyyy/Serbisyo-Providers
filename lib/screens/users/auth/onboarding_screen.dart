import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../../../services/preference_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;
  final int _totalPages = 4;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      icon: FontAwesomeIcons.magnifyingGlass,
      title: 'Discover Services',
      subtitle: 'Find the Perfect Service for You',
      description:
          'Browse through hundreds of professional services in your area. From home repairs to personal care, find exactly what you need with just a few taps.',
      features: [
        'Search by category or location',
        'View detailed service descriptions',
        'Check ratings and reviews',
        'Compare prices instantly'
      ],
      gradient: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
    ),
    OnboardingData(
      icon: FontAwesomeIcons.calendar,
      title: 'Easy Booking',
      subtitle: 'Schedule at Your Convenience',
      description:
          'Book appointments instantly or schedule for later. Choose your preferred time, date, and service provider with our simple booking system.',
      features: [
        'Real-time availability',
        'Instant confirmation',
        'Flexible scheduling',
        'Easy rescheduling options'
      ],
      gradient: [Colors.blue, Colors.blue.withOpacity(0.7)],
    ),
    OnboardingData(
      icon: FontAwesomeIcons.comments,
      title: 'Stay Connected',
      subtitle: 'Communicate Seamlessly',
      description:
          'Chat directly with service providers before, during, and after your appointment. Get updates, ask questions, and share requirements easily.',
      features: [
        'In-app messaging',
        'Real-time notifications',
        'Share photos and documents',
        'Track service progress'
      ],
      gradient: [Colors.green, Colors.green.withOpacity(0.7)],
    ),
    OnboardingData(
      icon: FontAwesomeIcons.star,
      title: 'Quality Assured',
      subtitle: 'Trusted Professionals Only',
      description:
          'All service providers are verified and rated by real customers. Enjoy peace of mind with our quality guarantee and secure payment system.',
      features: [
        'Verified professionals',
        'Customer reviews & ratings',
        'Secure payments',
        'Money-back guarantee'
      ],
      gradient: [Colors.orange, Colors.orange.withOpacity(0.7)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToLogin() async {
    await PreferenceService.setOnboardingSeen();
    Get.offAllNamed('/login');
  }

  Future<void> _skipOnboarding() async {
    await PreferenceService.setOnboardingSeen();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Skip Button
            _buildHeader(),

            // Page Indicator
            _buildPageIndicator(),

            // Onboarding Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),

            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.handshake,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Serbisyo',
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),

            // Skip Button
            TouchableWidget(
              onTap: _skipOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextWidget(
                  text: 'Skip',
                  fontSize: 14,
                  fontFamily: 'Bold',
                  color: AppColors.onSecondary.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _totalPages,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? _onboardingData[_currentPage].gradient[0]
                    : AppColors.onSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Icon Section
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: data.gradient[0].withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            // Title
            TextWidget(
              text: data.title,
              fontSize: 28,
              fontFamily: 'Bold',
              color: AppColors.primary,
              align: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtitle
            TextWidget(
              text: data.subtitle,
              fontSize: 16,
              fontFamily: 'Medium',
              color: data.gradient[0],
              align: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Description
            TextWidget(
              text: data.description,
              fontSize: 16,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
              align: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Features List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: data.gradient[0].withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: data.gradient[0].withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextWidget(
                        text: 'Key Features:',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: data.gradient[0],
                      ),
                      const SizedBox(height: 16),
                      ...data.features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: data.gradient[0],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextWidget(
                                  text: feature,
                                  fontSize: 14,
                                  fontFamily: 'Medium',
                                  color: AppColors.onSecondary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Previous Button
            if (_currentPage > 0)
              Expanded(
                child: TouchableWidget(
                  onTap: _previousPage,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.onSecondary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.arrowLeft,
                          size: 16,
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'Previous',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_currentPage > 0) const SizedBox(width: 16),

            // Next/Get Started Button
            Expanded(
              flex: _currentPage == 0 ? 1 : 1,
              child: TouchableWidget(
                onTap: _nextPage,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _onboardingData[_currentPage].gradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _onboardingData[_currentPage]
                            .gradient[0]
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: _currentPage == _totalPages - 1
                            ? 'Get Started'
                            : 'Next',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      FaIcon(
                        FontAwesomeIcons.arrowRight,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final List<Color> gradient;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.gradient,
  });
}
