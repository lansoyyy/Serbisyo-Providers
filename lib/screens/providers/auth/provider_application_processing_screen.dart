import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../../../widgets/button_widget.dart';

class ProviderApplicationProcessingScreen extends StatefulWidget {
  const ProviderApplicationProcessingScreen({Key? key}) : super(key: key);

  @override
  State<ProviderApplicationProcessingScreen> createState() =>
      _ProviderApplicationProcessingScreenState();
}

class _ProviderApplicationProcessingScreenState
    extends State<ProviderApplicationProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _applicationStatus = 'pending';
  DateTime? _applicationDate;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _scaleController.forward();
    });

    // Monitor application status
    _monitorApplicationStatus();
  }

  void _monitorApplicationStatus() {
    // Listen to application status changes
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final status = data['applicationStatus'] as String?;
          final appDate = data['applicationDate'] as Timestamp?;

          setState(() {
            _applicationStatus = status ?? 'pending';
            _applicationDate = appDate?.toDate();
          });

          // Navigate based on status change
          if (status == 'approved') {
            _showApprovedDialog();
          } else if (status == 'rejected') {
            _showRejectedDialog();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed('/provider-login');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header with back to login
                  Row(
                    children: [
                      TouchableWidget(
                        onTap: () {
                          Get.offAllNamed('/provider-login');
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
                          Get.offAllNamed('/provider-login');
                        },
                        child: TextWidget(
                          text: 'Back to Login',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main content - scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // Animated success icon
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange,
                                    Colors.orange.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                FontAwesomeIcons.clock,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Title
                          TextWidget(
                            text: _getStatusTitle(),
                            fontSize: 24,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                            align: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          TextWidget(
                            text: _getStatusSubtitle(),
                            fontSize: 16,
                            fontFamily: 'Medium',
                            color: AppColors.onSecondary,
                            align: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Application Date (if available)
                          if (_applicationDate != null) ...[
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
                              child: Row(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.calendar,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text:
                                        'Applied on ${_formatDate(_applicationDate!)}',
                                    fontSize: 13,
                                    fontFamily: 'Medium',
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Information Cards
                          _buildInfoCard(
                            icon: FontAwesomeIcons.magnifyingGlass,
                            title: 'Application Review',
                            description:
                                'Our team is currently reviewing your application and verifying the submitted documents.',
                            color: Colors.blue,
                          ),

                          const SizedBox(height: 12),

                          _buildInfoCard(
                            icon: FontAwesomeIcons.phone,
                            title: 'We\'ll Contact You',
                            description:
                                'We will reach out to you within 2-3 business days with updates about your application status.',
                            color: Colors.green,
                          ),

                          const SizedBox(height: 12),

                          _buildInfoCard(
                            icon: FontAwesomeIcons.envelope,
                            title: 'Check Your Email',
                            description:
                                'Important updates and notifications will be sent to your registered email address.',
                            color: Colors.purple,
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Bottom button
                  ButtonWidget(
                    label: 'Back to Login',
                    onPressed: () {
                      Get.offAllNamed('/provider-login');
                    },
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (_applicationStatus) {
      case 'approved':
        return 'Application Approved!';
      case 'rejected':
        return 'Application Review';
      case 'pending':
      default:
        return 'Application Submitted!';
    }
  }

  String _getStatusSubtitle() {
    switch (_applicationStatus) {
      case 'approved':
        return 'Congratulations! You can now start accepting bookings';
      case 'rejected':
        return 'We appreciate your interest in joining our network';
      case 'pending':
      default:
        return 'Thank you for your interest in joining our provider network';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showApprovedDialog() {
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
                text: 'Congratulations!',
                fontSize: 18,
                fontFamily: 'Bold',
                color: Colors.green,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text:
                    'Your provider application has been approved! You can now start accepting bookings and providing services to customers.',
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
                align: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.rocket,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextWidget(
                        text: 'Welcome to the Hanap Raket provider network!',
                        fontSize: 13,
                        fontFamily: 'Medium',
                        color: Colors.green,
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
                Get.offAllNamed('/provider-main');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: TextWidget(
                text: 'Get Started',
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

  void _showRejectedDialog() {
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
                text: 'Application Update',
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
                    'Unfortunately, your provider application has not been approved at this time. Please contact our support team for more information about reapplying.',
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
                child: Column(
                  children: [
                    Row(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.phone,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: '+63 912 345 6789',
                          fontSize: 13,
                          fontFamily: 'Bold',
                          color: Colors.red,
                        ),
                      ],
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
                Get.offAllNamed('/provider-login');
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
                text: 'Back to Login',
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  fontSize: 14,
                  fontFamily: 'Bold',
                  color: color,
                  align: TextAlign.left,
                ),
                const SizedBox(height: 4),
                TextWidget(
                  text: description,
                  fontSize: 13,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.8),
                  align: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
