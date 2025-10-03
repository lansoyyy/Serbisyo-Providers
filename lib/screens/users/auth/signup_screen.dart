import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../utils/colors.dart';
import '../../../utils/const.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../../../widgets/app_text_form_field.dart';
import '../../../widgets/button_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showErrorSnackbar('Please agree to Terms & Conditions');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final userData = {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'profilePicture': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      _showSuccessSnackbar('Account created successfully!');
      Get.offAllNamed('/main');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create account';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email is already in use.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'operation-not-allowed':
          message = 'Operation not allowed. Enable Email/Password in Firebase.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
      }
      _showErrorSnackbar(message);
    } catch (_) {
      _showErrorSnackbar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to get user after Google sign-in');
      }

      // Extract user information
      final String uid = user.uid;
      final String email = user.email ?? '';
      final String displayName = user.displayName ?? '';
      final String photoURL = user.photoURL ?? '';

      // Split display name into first and last name
      final List<String> nameParts = displayName.split(' ');
      final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Store user data in Firestore
      final userData = {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': '', // Empty since Google doesn't provide phone
        'profilePicture': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'signupMethod': 'google', // Track signup method
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      _showSuccessSnackbar('Account created successfully with Google!');
      Get.offAllNamed('/main');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to sign in with Google';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with the same email address but different sign-in credentials.';
          break;
        case 'invalid-credential':
          message = 'The credential received is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          message = 'Operation not allowed. Enable Google Sign-In in Firebase.';
          break;
        case 'user-disabled':
          message = 'The user account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found for this account.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'email-already-in-use':
          message = 'Email is already in use.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
      }
      _showErrorSnackbar(message);
    } catch (e) {
      _showErrorSnackbar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get the user data
        final Map<String, dynamic> userData =
            await FacebookAuth.instance.getUserData();

        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);

        // Sign in to Firebase with the Facebook credential
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);

        final User? user = userCredential.user;
        if (user == null) {
          throw Exception('Failed to get user after Facebook sign-in');
        }

        // Extract user information
        final String uid = user.uid;
        final String email = user.email ?? userData['email'] ?? '';
        final String displayName = user.displayName ?? userData['name'] ?? '';
        final String photoURL =
            user.photoURL ?? userData['picture']['data']['url'] ?? '';

        // Split display name into first and last name
        final List<String> nameParts = displayName.split(' ');
        final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        // Store user data in Firestore
        final userDataFirestore = {
          'uid': uid,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': '', // Empty since Facebook doesn't provide phone
          'profilePicture': photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'signupMethod': 'facebook', // Track signup method
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userDataFirestore, SetOptions(merge: true));

        _showSuccessSnackbar('Account created successfully with Facebook!');
        Get.offAllNamed('/main');
      } else if (result.status == LoginStatus.cancelled) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        // Handle other errors
        throw Exception('Facebook sign-in failed: ${result.message}');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to sign in with Facebook';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with the same email address but different sign-in credentials.';
          break;
        case 'invalid-credential':
          message = 'The credential received is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          message =
              'Operation not allowed. Enable Facebook Sign-In in Firebase.';
          break;
        case 'user-disabled':
          message = 'The user account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found for this account.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'email-already-in-use':
          message = 'Email is already in use.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
      }
      _showErrorSnackbar(message);
    } catch (e) {
      _showErrorSnackbar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            child: Column(
              children: [
                // Header Section
                _buildHeader(),

                // Signup Form Section
                _buildSignupForm(),
              ],
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
            // Back Button and Logo Row
            Row(
              children: [
                TouchableWidget(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
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
                        FontAwesomeIcons.handshake,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
            const SizedBox(height: 16),

            // Welcome Text
            TextWidget(
              text: 'Create Account',
              fontSize: 24,
              fontFamily: 'Bold',
              color: AppColors.primary,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Join Serbisyo and find the best services',
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

  Widget _buildSignupForm() {
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
              // Social Signup Buttons
              _buildSocialSignupSection(),

              const SizedBox(height: 24),

              // Divider
              _buildDivider(),

              const SizedBox(height: 24),

              // Name Fields Row
              _buildNameFields(),

              const SizedBox(height: 16),

              // Email Field
              _buildEmailField(),

              const SizedBox(height: 16),

              // Phone Field
              _buildPhoneField(),

              const SizedBox(height: 16),

              // Password Field
              _buildPasswordField(),

              const SizedBox(height: 16),

              // Confirm Password Field
              _buildConfirmPasswordField(),

              const SizedBox(height: 12),

              // Terms & Conditions
              _buildTermsSection(),

              const SizedBox(height: 24),

              // Signup Button
              _buildSignupButton(),

              const SizedBox(height: 16),

              // Login Link
              _buildLoginLink(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSignupSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextWidget(
          text: 'Quick Signup',
          fontSize: 16,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Google Signup
            Expanded(
              child: TouchableWidget(
                onTap: _isLoading ? null : _handleGoogleSignup,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.google,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      TextWidget(
                        text: 'Google',
                        fontSize: 13,
                        fontFamily: 'Bold',
                        color: AppColors.onSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Facebook Signup
            Expanded(
              child: TouchableWidget(
                onTap: _isLoading ? null : _handleFacebookSignup,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1877F2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.facebookF,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      TextWidget(
                        text: 'Facebook',
                        fontSize: 13,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.onSecondary.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextWidget(
            text: 'or create with email',
            fontSize: 14,
            fontFamily: 'Medium',
            color: AppColors.onSecondary.withOpacity(0.6),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.onSecondary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        // First Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: 'First Name',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              AppTextFormField(
                controller: _firstNameController,
                labelText: 'First name',
                hintText: 'Enter first name',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FaIcon(
                    FontAwesomeIcons.user,
                    size: 16,
                    color: AppColors.onSecondary.withOpacity(0.6),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Last Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: 'Last Name',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              AppTextFormField(
                controller: _lastNameController,
                labelText: 'Last name',
                hintText: 'Enter last name',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FaIcon(
                    FontAwesomeIcons.user,
                    size: 16,
                    color: AppColors.onSecondary.withOpacity(0.6),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextWidget(
          text: 'Email Address',
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: _emailController,
          labelText: 'Enter your email',
          hintText: 'example@email.com',
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: FaIcon(
              FontAwesomeIcons.envelope,
              size: 16,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
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

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextWidget(
          text: 'Phone Number',
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: _phoneController,
          labelText: 'Enter your phone number',
          hintText: '+1 (555) 123-4567',
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: FaIcon(
              FontAwesomeIcons.phone,
              size: 16,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
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
      mainAxisSize: MainAxisSize.min,
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
          labelText: 'Create a password',
          hintText: 'At least 8 characters',
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.visiblePassword,
          obscureText: !_isPasswordVisible,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: FaIcon(
              FontAwesomeIcons.lock,
              size: 16,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          suffixIcon: TouchableWidget(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FaIcon(
                _isPasswordVisible
                    ? FontAwesomeIcons.eyeSlash
                    : FontAwesomeIcons.eye,
                size: 16,
                color: AppColors.onSecondary.withOpacity(0.6),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextWidget(
          text: 'Confirm Password',
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: _confirmPasswordController,
          labelText: 'Confirm your password',
          hintText: 'Re-enter your password',
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          obscureText: !_isConfirmPasswordVisible,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: FaIcon(
              FontAwesomeIcons.lock,
              size: 16,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          suffixIcon: TouchableWidget(
            onTap: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FaIcon(
                _isConfirmPasswordVisible
                    ? FontAwesomeIcons.eyeSlash
                    : FontAwesomeIcons.eye,
                size: 16,
                color: AppColors.onSecondary.withOpacity(0.6),
              ),
            ),
          ),
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
      ],
    );
  }

  Widget _buildTermsSection() {
    return TouchableWidget(
      onTap: () {
        setState(() {
          _agreeToTerms = !_agreeToTerms;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _agreeToTerms ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreeToTerms
                    ? AppColors.primary
                    : AppColors.onSecondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _agreeToTerms
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      color: AppColors.onSecondary.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Regular',
                    ),
                  ),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Bold',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(
                      color: AppColors.onSecondary.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Regular',
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Bold',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      child: ButtonWidget(
        onPressed: () => _handleSignup(),
        label: 'Create Account',
        height: 50,
        radius: 12,
        color: AppColors.primary,
        loading: _isLoading,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TouchableWidget(
        onTap: () {
          Navigator.pop(context);
        },
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Already have an account? ",
                style: TextStyle(
                  color: AppColors.onSecondary.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Regular',
                ),
              ),
              TextSpan(
                text: 'Sign In',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Bold',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.checkCircle,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: message,
                fontSize: 14,
                fontFamily: 'Medium',
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.exclamationCircle,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: message,
                fontSize: 14,
                fontFamily: 'Medium',
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
