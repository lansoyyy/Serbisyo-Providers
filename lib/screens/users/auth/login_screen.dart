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
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      _showSuccessSnackbar('Signed in successfully!');
      Get.offAllNamed('/main');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to sign in';
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
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

  Future<void> _handleGoogleLogin() async {
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

      // Check if user exists in Firestore
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // If user doesn't exist in Firestore, create a new document
      if (!userDoc.exists) {
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
      }

      _showSuccessSnackbar('Signed in successfully with Google!');
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

  Future<void> _handleFacebookLogin() async {
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

        // Check if user exists in Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // If user doesn't exist in Firestore, create a new document
        if (!userDoc.exists) {
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
        }

        _showSuccessSnackbar('Signed in successfully with Facebook!');
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
                FontAwesomeIcons.handshake,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Welcome Text
            TextWidget(
              text: 'Welcome Back!',
              fontSize: 24,
              fontFamily: 'Bold',
              color: AppColors.primary,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Sign in to continue using Serbisyo',
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
              // Social Login Buttons
              _buildSocialLoginSection(),

              const SizedBox(height: 24),

              // Divider
              _buildDivider(),

              const SizedBox(height: 24),

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

  Widget _buildSocialLoginSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextWidget(
          text: 'Quick Login',
          fontSize: 16,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Google Login
            Expanded(
              child: TouchableWidget(
                onTap: _isLoading ? null : _handleGoogleLogin,
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
            // Facebook Login
            Expanded(
              child: TouchableWidget(
                onTap: _isLoading ? null : _handleFacebookLogin,
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
            text: 'or continue with email',
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
          labelText: 'Enter your password',
          hintText: 'At least 6 characters',
          textInputAction: TextInputAction.done,
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
        TouchableWidget(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _rememberMe
                        ? AppColors.primary
                        : AppColors.onSecondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              TextWidget(
                text: 'Remember me',
                fontSize: 14,
                fontFamily: 'Medium',
                color: AppColors.onSecondary,
              ),
            ],
          ),
        ),
        TouchableWidget(
          onTap: () {
            // Navigate to forgot password screen
            _showForgotPasswordDialog();
          },
          child: TextWidget(
            text: 'Forgot Password?',
            fontSize: 14,
            fontFamily: 'Bold',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ButtonWidget(
        onPressed: () => _handleLogin(),
        label: 'Sign In',
        height: 50,
        radius: 12,
        color: AppColors.primary,
        loading: _isLoading,
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: TouchableWidget(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignupScreen(),
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(
                  color: AppColors.onSecondary.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Regular',
                ),
              ),
              TextSpan(
                text: 'Sign Up',
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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: TextWidget(
          text: 'Reset Password',
          fontSize: 20,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              text:
                  'Enter your email address and we\'ll send you a link to reset your password.',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            AppTextFormField(
              controller: emailController,
              labelText: 'Enter your email',
              hintText: 'example@email.com',
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(16),
                child: FaIcon(
                  FontAwesomeIcons.envelope,
                  size: 16,
                  color: AppColors.onSecondary.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 14,
              fontFamily: 'Bold',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              Navigator.pop(context);
              if (email.isEmpty || !GetUtils.isEmail(email)) {
                _showErrorSnackbar('Enter a valid email to reset password');
                return;
              }
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                _showSuccessSnackbar('Password reset link sent to your email!');
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to send reset email';
                if (e.code == 'user-not-found') {
                  message = 'No user found with this email.';
                } else if (e.code == 'invalid-email') {
                  message = 'The email address is badly formatted.';
                }
                _showErrorSnackbar(message);
              } catch (_) {
                _showErrorSnackbar(
                    'Something went wrong. Please try again later.');
              }
            },
            child: TextWidget(
              text: 'Send',
              fontSize: 14,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ),
        ],
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
