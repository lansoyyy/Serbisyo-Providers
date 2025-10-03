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

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({Key? key}) : super(key: key);

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

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
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if user is a provider
      final userDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // User is not a provider
        await FirebaseAuth.instance.signOut();
        throw Exception(
            'Provider account not found. Please check your credentials or register as a provider.');
      }

      final providerData = userDoc.data()!;
      final applicationStatus = providerData['applicationStatus'] as String?;

      // Navigate based on application status
      switch (applicationStatus) {
        case 'pending':
          Get.offAllNamed('/provider-application-processing');
          break;
        case 'approved':
          Get.offAllNamed('/provider-main');
          break;
        case 'rejected':
          await FirebaseAuth.instance.signOut();
          _showRejectionDialog();
          break;
        default:
          Get.offAllNamed('/provider-main');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No provider account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
      }

      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showForgotPasswordDialog() {
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
                FontAwesomeIcons.circleInfo,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Password Recovery',
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
                    'To recover your provider account password, please contact our customer support team.',
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
                align: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
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
                          FontAwesomeIcons.envelope,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'support@hanapraket.com',
                          fontSize: 13,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.phone,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: '+63 912 345 6789',
                          fontSize: 13,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: 'Got it',
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
                text: 'Login Failed',
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

  void _showRejectionDialog() {
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
                FontAwesomeIcons.circleXmark,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Application Rejected',
                fontSize: 18,
                fontFamily: 'Bold',
                color: Colors.red,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text:
                    'Unfortunately, your provider application has been rejected. Please contact our support team for more information.',
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
                align: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.envelope,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    TextWidget(
                      text: 'support@hanapraket.com',
                      fontSize: 13,
                      fontFamily: 'Bold',
                      color: Colors.red,
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: TextWidget(
                text: 'Understood',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),

                  // Login Form Section
                  Expanded(
                    child: _buildLoginForm(),
                  ),
                ],
              ),
            ),
          ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.white.withOpacity(0.8),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo Section
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.briefcase,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Welcome Text for Providers
            TextWidget(
              text: 'Provider Portal',
              fontSize: 24,
              fontFamily: 'Bold',
              color: AppColors.primary,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Sign in to manage your services and clients',
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

  Widget _buildLoginForm() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email Field
              _buildEmailField(),

              const SizedBox(height: 16),

              // Password Field
              _buildPasswordField(),

              const SizedBox(height: 12),

              // Remember Me & Forgot Password
              _buildRememberMeSection(),

              const SizedBox(height: 24),

              // Login Button
              _buildLoginButton(),

              const SizedBox(height: 16),

              // Sign Up Link
              _buildSignUpLink(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Email',
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: const Icon(
            FontAwesomeIcons.envelope,
            size: 18,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
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
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Password',
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Enter your password',
          prefixIcon: const Icon(
            FontAwesomeIcons.lock,
            size: 18,
          ),
          suffixIcon: TouchableWidget(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Icon(
              _isPasswordVisible
                  ? FontAwesomeIcons.eye
                  : FontAwesomeIcons.eyeSlash,
              size: 18,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          obscureText: !_isPasswordVisible,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberMeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextWidget(
              text: 'Remember me',
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
            ),
          ],
        ),
        TouchableWidget(
          onTap: () {
            _showForgotPasswordDialog();
          },
          child: TextWidget(
            text: 'Forgot Password?',
            fontSize: 12,
            fontFamily: 'Bold',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Center(
      child: ButtonWidget(
        label: 'Sign In to Provider Portal',
        onPressed: _isLoading ? () {} : _handleLogin,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: TouchableWidget(
        onTap: () {
          // Navigate to provider signup screen
          Get.toNamed('/provider-signup');
        },
        child: RichText(
          text: TextSpan(
            text: "Don't have a provider account? ",
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Regular',
              color: Colors.black54,
            ),
            children: [
              TextSpan(
                text: 'Register as Provider',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
