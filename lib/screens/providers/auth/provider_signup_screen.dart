import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../../../widgets/app_text_form_field.dart';
import '../../../widgets/button_widget.dart';

class ProviderSignupScreen extends StatefulWidget {
  const ProviderSignupScreen({Key? key}) : super(key: key);

  @override
  State<ProviderSignupScreen> createState() => _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends State<ProviderSignupScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _personalInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _businessInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _accountInfoFormKey = GlobalKey<FormState>();

  // Personal Information Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  // Business Information Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  // Account Information Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  int _currentPage = 0;
  List<String> _selectedCategories =
      []; // Changed from _selectedServices to _selectedCategories
  int _selectedCategoryIndex = 0;

  // Photo upload variables
  String? _profileImagePath;
  String? _policeClearanceImagePath;
  String? _certificateImagePath;

  // Service categories
  final List<String> _serviceCategories = [
    'Residential',
    'Commercial',
    'Specialized',
    'Maintenance',
  ];

  // Available services data
  final List<Map<String, dynamic>> _availableServices = [
    // Residential Services
    {
      'name': 'Regular House Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.house,
      'color': Colors.blue
    },
    {
      'name': 'Deep Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.broom,
      'color': Colors.purple
    },
    {
      'name': 'Move-in/out Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.boxOpen,
      'color': Colors.orange
    },
    {
      'name': 'Post-Construction Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.hammer,
      'color': Colors.brown
    },

    // Commercial Services
    {
      'name': 'Office Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.building,
      'color': Colors.green
    },
    {
      'name': 'Retail Space Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.store,
      'color': Colors.blue
    },
    {
      'name': 'Restaurant Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.utensils,
      'color': Colors.red
    },
    {
      'name': 'Medical Facility Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.hospital,
      'color': Colors.teal
    },

    // Specialized Services
    {
      'name': 'Carpet Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.rug,
      'color': Colors.red
    },
    {
      'name': 'Window Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.windowMaximize,
      'color': Colors.cyan
    },
    {
      'name': 'Upholstery Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.couch,
      'color': Colors.indigo
    },
    {
      'name': 'Pressure Washing',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.sprayCan,
      'color': Colors.lime
    },
    {
      'name': 'Pool Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.water,
      'color': Colors.blue
    },

    // Maintenance Services
    {
      'name': 'Plumbing',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.wrench,
      'color': Colors.blue
    },
    {
      'name': 'Electrical Work',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.bolt,
      'color': Colors.yellow
    },
    {
      'name': 'HVAC Services',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.fan,
      'color': Colors.green
    },
    {
      'name': 'Appliance Repair',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.screwdriver,
      'color': Colors.grey
    },
    {
      'name': 'Landscaping',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.leaf,
      'color': Colors.green
    },
    {
      'name': 'Pest Control',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.bug,
      'color': Colors.brown
    },
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
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
    _slideController.dispose();
    _fadeController.dispose();

    // Dispose all controllers
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _businessNameController.dispose();
    _experienceController.dispose();
    _availabilityController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      bool isValid = false;

      switch (_currentPage) {
        case 0:
          isValid = _personalInfoFormKey.currentState!.validate();
          break;
        case 1:
          isValid = _businessInfoFormKey.currentState!.validate();

          if (isValid && _selectedCategories.isEmpty) {
            setState(() {}); // Trigger rebuild to show validation message
            isValid = false;
          }
          if (isValid &&
              (_profileImagePath == null ||
                  _policeClearanceImagePath == null)) {
            setState(() {}); // Trigger rebuild to show validation message
          }
          break;
      }

      if (isValid) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
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

  void _handleSignup() async {
    if (!_accountInfoFormKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      _showTermsDialog();
      return;
    }

    // Check for required documents
    if (_profileImagePath == null || _policeClearanceImagePath == null) {
      _showDocumentRequiredDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Firebase Auth account
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      // Update display name
      await userCredential.user!
          .updateDisplayName(_fullNameController.text.trim());

      // Create provider profile in Firestore
      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        // Personal Information
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'location': _locationController.text.trim(),
        'about': _aboutController.text.trim(),

        // Business Information
        'businessName': _businessNameController.text.trim(),
        'experience': _experienceController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'serviceCategories':
            _selectedCategories, // Changed from 'services' to 'serviceCategories'

        // Account Information
        'username': _usernameController.text.trim(),

        // Application Status
        'applicationStatus': 'pending',
        'applicationDate': FieldValue.serverTimestamp(),
        'profilePicture': _profileImagePath != null,

        // Document Upload Status
        'documents': {
          'profilePicture': _profileImagePath != null,
          'policeClearance': _policeClearanceImagePath != null,
          'certificate': _certificateImagePath != null,
        },

        // Metadata
        'isActive': false,
        'isVerified': false,
        'rating': 0.0,
        'totalBookings': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create initial provider stats
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('stats')
          .doc('general')
          .set({
        'totalEarnings': 0.0,
        'completedServices': 0,
        'cancelledServices': 0,
        'averageRating': 0.0,
        'totalReviews': 0,
        'responseTime': 0,
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Sign out the user (they need admin approval)
      await FirebaseAuth.instance.signOut();

      setState(() {
        _isLoading = false;
      });

      // Show success dialog and navigate
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Registration failed. Please try again.';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account with this email already exists.';
          break;
        case 'weak-password':
          errorMessage =
              'Password is too weak. Please choose a stronger password.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
      }

      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.circleExclamation,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Terms Required',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: TextWidget(
            text:
                'Please agree to the Terms of Service and Privacy Policy to continue with your provider registration.',
            fontSize: 14,
            fontFamily: 'Regular',
            color: AppColors.onSecondary,
            align: TextAlign.left,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: TextWidget(
                text: 'OK',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDocumentRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.circleExclamation,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Documents Required',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text:
                    'Please upload the following required documents to complete your registration:',
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
                align: TextAlign.left,
              ),
              const SizedBox(height: 12),
              if (_profileImagePath == null)
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.user,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    TextWidget(
                      text: 'Profile Picture (formal photo)',
                      fontSize: 13,
                      fontFamily: 'Medium',
                      color: Colors.red,
                    ),
                  ],
                ),
              if (_profileImagePath == null) const SizedBox(height: 8),
              if (_policeClearanceImagePath == null)
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.shieldHalved,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    TextWidget(
                      text: 'Police Clearance',
                      fontSize: 13,
                      fontFamily: 'Medium',
                      color: Colors.red,
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: TextWidget(
                text: 'OK',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.circleCheck,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Application Submitted!',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text:
                    'Thank you for applying to join our provider network! Your application has been submitted successfully.',
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
                align: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.clock,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextWidget(
                        text:
                            'We are reviewing your application and will contact you within 2-3 business days.',
                        fontSize: 13,
                        fontFamily: 'Medium',
                        color: Colors.orange,
                        align: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAllNamed('/provider-application-processing');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: TextWidget(
                text: 'Continue',
                fontSize: 14,
                fontFamily: 'Bold',
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.circleExclamation,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Registration Failed',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: TextWidget(
            text: message,
            fontSize: 14,
            fontFamily: 'Regular',
            color: AppColors.onSecondary,
            align: TextAlign.left,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: TextWidget(
                text: 'OK',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),

            // Progress Indicator
            _buildProgressIndicator(),

            // Form Pages
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildPersonalInfoPage(),
                    _buildBusinessInfoPage(),
                    _buildAccountInfoPage(),
                  ],
                ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          children: [
            // Back Button Row
            Row(
              children: [
                TouchableWidget(
                  onTap: () {
                    if (_currentPage > 0) {
                      _previousPage();
                    } else {
                      Get.back();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FontAwesomeIcons.arrowLeft,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                TouchableWidget(
                  onTap: () {
                    Get.toNamed('/provider-login');
                  },
                  child: TextWidget(
                    text: 'Already have an account?',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Logo and Title
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.userPlus,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextWidget(
              text: 'Join as Provider',
              fontSize: 24,
              fontFamily: 'Bold',
              color: AppColors.primary,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: _getSubtitleForPage(),
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Personal', _currentPage >= 0),
          _buildProgressLine(_currentPage >= 1),
          _buildProgressStep(1, 'Business', _currentPage >= 1),
          _buildProgressLine(_currentPage >= 2),
          _buildProgressStep(2, 'Account', _currentPage >= 2),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive
                  ? Icon(
                      step < _currentPage
                          ? FontAwesomeIcons.check
                          : FontAwesomeIcons.user,
                      size: 14,
                      color: Colors.white,
                    )
                  : TextWidget(
                      text: '${step + 1}',
                      fontSize: 14,
                      fontFamily: 'Bold',
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextWidget(
            text: label,
            fontSize: 12,
            fontFamily: 'Medium',
            color: isActive ? AppColors.primary : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 26),
        color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _personalInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Personal Information', FontAwesomeIcons.user),
            const SizedBox(height: 20),
            _buildFormField(
              'Full Name',
              _fullNameController,
              'Enter your full name',
              FontAwesomeIcons.user,
              TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Phone Number',
              _phoneController,
              '+63 912 345 6789',
              FontAwesomeIcons.phone,
              TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Email Address',
              _emailController,
              'your.email@example.com',
              FontAwesomeIcons.envelope,
              TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!GetUtils.isEmail(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Location',
              _locationController,
              'City, Province',
              FontAwesomeIcons.locationDot,
              TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'About Me',
              _aboutController,
              'Brief description about yourself and your expertise',
              FontAwesomeIcons.circleInfo,
              TextInputType.multiline,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please tell us about yourself';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _businessInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Business Information', FontAwesomeIcons.briefcase),
            const SizedBox(height: 20),
            _buildFormField(
              'Business/Service Name',
              _businessNameController,
              'Your business or service name',
              FontAwesomeIcons.building,
              TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Years of Experience',
              _experienceController,
              'e.g., 5 years',
              FontAwesomeIcons.clock,
              TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your experience';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildServicesSelection(),
            const SizedBox(height: 16),
            _buildFormField(
              'Availability',
              _availabilityController,
              'e.g., Mon-Sat, 8:00 AM - 6:00 PM',
              FontAwesomeIcons.calendar,
              TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your availability';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _accountInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Account Setup', FontAwesomeIcons.shield),
            const SizedBox(height: 20),

            _buildFormField(
              'Username',
              _usernameController,
              'Choose a unique username',
              FontAwesomeIcons.at,
              TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildPasswordField(
              'Password',
              _passwordController,
              'Create a strong password',
              _isPasswordVisible,
              () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildPasswordField(
              'Confirm Password',
              _confirmPasswordController,
              'Re-enter your password',
              _isConfirmPasswordVisible,
              () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Document Uploads Section
            _buildDocumentUploads(),

            const SizedBox(height: 24),

            // Terms and Conditions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TouchableWidget(
                    onTap: () {
                      setState(() {
                        _agreeToTerms = !_agreeToTerms;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.black54,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(
                            text: ' and ',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.black54,
                            ),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        TextWidget(
          text: title,
          fontSize: 20,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
    TextInputType keyboardType, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: controller,
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            size: 18,
            color: AppColors.primary.withOpacity(0.7),
          ),
          keyboardType: keyboardType,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    String hint,
    bool isVisible,
    VoidCallback onToggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: controller,
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            FontAwesomeIcons.lock,
            size: 18,
            color: AppColors.primary.withOpacity(0.7),
          ),
          suffixIcon: TouchableWidget(
            onTap: onToggleVisibility,
            child: Icon(
              isVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
              size: 18,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          obscureText: !isVisible,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: TouchableWidget(
                onTap: _previousPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.arrowLeft,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      TextWidget(
                        text: 'Back',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ButtonWidget(
              label: _currentPage == 2
                  ? (_isLoading ? 'Creating Account...' : 'Create Account')
                  : 'Continue',
              onPressed: _isLoading
                  ? () {}
                  : (_currentPage == 2 ? _handleSignup : _nextPage),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FontAwesomeIcons.wrench,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Service Categories',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  TextWidget(
                    text: 'Select the categories of services you provide',
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            if (_selectedCategories.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextWidget(
                  text: '${_selectedCategories.length} selected',
                  fontSize: 11,
                  fontFamily: 'Bold',
                  color: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Category Selection Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Available Categories:',
                fontSize: 14,
                fontFamily: 'Medium',
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _serviceCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return _buildCategoryChip(category, isSelected);
                }).toList(),
              ),
            ],
          ),
        ),

        // Validation message
        if (_selectedCategories.isEmpty) ...[
          const SizedBox(height: 8),
          TextWidget(
            text: 'Please select at least one category',
            fontSize: 12,
            fontFamily: 'Regular',
            color: Colors.red,
          ),
        ],

        // Selected Categories Summary (if any)
        if (_selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedCategoriesSummary(),
        ],
      ],
    );
  }

  Widget _buildDocumentUploads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FontAwesomeIcons.camera,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Required Documents',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  TextWidget(
                    text: 'Upload required documents for verification',
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Profile Picture Upload (Required)
        _buildPhotoUploadCard(
          title: 'Profile Picture',
          subtitle: 'Upload a formal photo of yourself',
          isRequired: true,
          imagePath: _profileImagePath,
          onTap: () => _selectImage('profile'),
          icon: FontAwesomeIcons.user,
          color: Colors.blue,
        ),

        const SizedBox(height: 12),

        // Police Clearance Upload (Required)
        _buildPhotoUploadCard(
          title: 'Police Clearance',
          subtitle: 'Upload a clear photo of your police clearance',
          isRequired: true,
          imagePath: _policeClearanceImagePath,
          onTap: () => _selectImage('clearance'),
          icon: FontAwesomeIcons.shieldHalved,
          color: Colors.green,
        ),

        const SizedBox(height: 12),

        // Certificate Upload (Optional)
        _buildPhotoUploadCard(
          title: 'Certificate (Optional)',
          subtitle: 'Upload NC2, diploma, or relevant certificates',
          isRequired: false,
          imagePath: _certificateImagePath,
          onTap: () => _selectImage('certificate'),
          icon: FontAwesomeIcons.certificate,
          color: Colors.orange,
        ),

        // Validation messages
        if (_profileImagePath == null || _policeClearanceImagePath == null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.circleExclamation,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextWidget(
                    text: 'Profile picture and police clearance are required',
                    fontSize: 12,
                    fontFamily: 'Medium',
                    color: Colors.red,
                    align: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required String subtitle,
    required bool isRequired,
    required String? imagePath,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: imagePath != null
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath != null
                ? color.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: imagePath != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: imagePath != null
                    ? color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                imagePath != null ? FontAwesomeIcons.check : icon,
                size: imagePath != null ? 20 : 24,
                color: imagePath != null ? color : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextWidget(
                        text: title,
                        fontSize: 14,
                        fontFamily: 'Bold',
                        color: imagePath != null ? color : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      if (isRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextWidget(
                            text: 'Required',
                            fontSize: 10,
                            fontFamily: 'Bold',
                            color: Colors.red,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextWidget(
                            text: 'Optional',
                            fontSize: 10,
                            fontFamily: 'Bold',
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: imagePath != null
                        ? 'Photo uploaded successfully'
                        : subtitle,
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: imagePath != null
                        ? color
                        : AppColors.onSecondary.withOpacity(0.7),
                    align: TextAlign.left,
                  ),
                ],
              ),
            ),

            // Upload Icon
            Icon(
              imagePath != null
                  ? FontAwesomeIcons.penToSquare
                  : FontAwesomeIcons.plus,
              size: 16,
              color: imagePath != null ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _selectImage(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TextWidget(
                text: 'Select Photo Source',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TouchableWidget(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromSource(type, 'camera');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              FontAwesomeIcons.camera,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: 'Camera',
                              fontSize: 14,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TouchableWidget(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromSource(type, 'gallery');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              FontAwesomeIcons.images,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: 'Gallery',
                              fontSize: 14,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _pickImageFromSource(String type, String source) {
    // Simulate image picking
    // In a real app, you would use image_picker plugin here
    setState(() {
      switch (type) {
        case 'profile':
          _profileImagePath = 'path/to/profile_image.jpg';
          break;
        case 'clearance':
          _policeClearanceImagePath = 'path/to/police_clearance.jpg';
          break;
        case 'certificate':
          _certificateImagePath = 'path/to/certificate.jpg';
          break;
      }
    });

    // Show success message
    _showImageUploadSuccess(type);
  }

  void _showImageUploadSuccess(String type) {
    String documentName = '';
    switch (type) {
      case 'profile':
        documentName = 'Profile Picture';
        break;
      case 'clearance':
        documentName = 'Police Clearance';
        break;
      case 'certificate':
        documentName = 'Certificate';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              FontAwesomeIcons.circleCheck,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            TextWidget(
              text: '$documentName uploaded successfully!',
              fontSize: 14,
              fontFamily: 'Medium',
              color: Colors.white,
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    // Get category icon and color
    IconData categoryIcon;
    Color categoryColor;

    switch (category) {
      case 'Residential':
        categoryIcon = FontAwesomeIcons.house;
        categoryColor = Colors.blue;
        break;
      case 'Commercial':
        categoryIcon = FontAwesomeIcons.building;
        categoryColor = Colors.green;
        break;
      case 'Specialized':
        categoryIcon = FontAwesomeIcons.star;
        categoryColor = Colors.orange;
        break;
      case 'Maintenance':
        categoryIcon = FontAwesomeIcons.wrench;
        categoryColor = Colors.red;
        break;
      default:
        categoryIcon = FontAwesomeIcons.briefcase;
        categoryColor = AppColors.primary;
    }

    return TouchableWidget(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(category);
          } else {
            _selectedCategories.add(category);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? categoryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? categoryColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon,
              size: 16,
              color: isSelected
                  ? categoryColor
                  : AppColors.onSecondary.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                fontSize: 14,
                fontFamily: isSelected ? 'Bold' : 'Medium',
                color: isSelected
                    ? categoryColor
                    : AppColors.onSecondary.withOpacity(0.8),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                FontAwesomeIcons.check,
                size: 12,
                color: categoryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCategoriesSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.listCheck,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              TextWidget(
                text: 'Selected Categories (${_selectedCategories.length})',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selectedCategories.map((categoryName) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextWidget(
                      text: categoryName,
                      fontSize: 11,
                      fontFamily: 'Medium',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    TouchableWidget(
                      onTap: () {
                        setState(() {
                          _selectedCategories.remove(categoryName);
                        });
                      },
                      child: Icon(
                        FontAwesomeIcons.xmark,
                        size: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSubtitleForPage() {
    switch (_currentPage) {
      case 0:
        return 'Tell us about yourself';
      case 1:
        return 'Share your business details';
      case 2:
        return 'Create your account credentials';
      default:
        return '';
    }
  }
}
