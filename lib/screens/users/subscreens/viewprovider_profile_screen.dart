import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import 'message_screen.dart';

class ViewProviderProfileScreen extends StatefulWidget {
  final String providerId; // Add provider ID parameter
  final String? initialSelectedService;

  const ViewProviderProfileScreen({
    Key? key,
    required this.providerId, // Require provider ID instead of individual parameters
    this.initialSelectedService,
  }) : super(key: key);

  @override
  State<ViewProviderProfileScreen> createState() =>
      _ViewProviderProfileScreenState();
}

class _ViewProviderProfileScreenState extends State<ViewProviderProfileScreen>
    with TickerProviderStateMixin {
  String _selectedService = '';
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Provider data
  Map<String, dynamic>? _providerData;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _certifications = []; // Add certifications list
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Set the initial selected service if provided
    _selectedService = widget.initialSelectedService ?? '';

    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Load provider data
    _loadProviderData();
  }

  // Load provider data from Firebase
  Future<void> _loadProviderData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Fetch provider document
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .get();

      if (!providerDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Provider not found';
        });
        return;
      }

      final providerData = providerDoc.data() as Map<String, dynamic>;

      // Fetch provider services
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .collection('services')
          .get();

      final servicesList = <Map<String, dynamic>>[];
      for (var doc in servicesSnapshot.docs) {
        final serviceData = doc.data() as Map<String, dynamic>;
        servicesList.add({
          'id': doc.id,
          'name': serviceData['name'] as String? ?? 'Service',
          'description': serviceData['description'] as String? ?? '',
          'price': serviceData['price'] as num? ?? 0,
          'duration':
              serviceData['duration'] as String? ?? 'Duration not specified',
          'category': serviceData['category'] as String? ?? 'General',
        });
      }

      // Fetch provider reviews
      print('Fetching reviews for provider: ${widget.providerId}');
      final reviewsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      print('Reviews snapshot size: ${reviewsSnapshot.docs.length}');

      final reviewsList = <Map<String, dynamic>>[];
      for (var doc in reviewsSnapshot.docs.where(
        (element) {
          return element['providerId'] == widget.providerId &&
              element['rated'] == true;
        },
      )) {
        final reviewData = doc.data() as Map<String, dynamic>;
        reviewsList.add({
          'id': doc.id,
          'customerName': reviewData['userFullName'] as String? ?? 'Customer',
          'rating': reviewData['rating'] as num? ?? 0,
          'comment': reviewData['review'] as String? ?? '',
          'date': _formatTimestamp(reviewData['bookingDate']),
          'service': reviewData['serviceName'] as String? ?? 'Service',
        });
      }

      // Fetch provider certifications
      final certificationsSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .collection('certifications')
          .orderBy('year', descending: true)
          .get();

      final certificationsList = <Map<String, dynamic>>[];
      for (var doc in certificationsSnapshot.docs) {
        final certData = doc.data() as Map<String, dynamic>;
        certificationsList.add({
          'id': doc.id,
          'name': certData['name'] as String? ?? 'Certification',
          'issuer': certData['issuer'] as String? ?? 'Issuer',
          'year': certData['year'] as String? ?? 'Year',
        });
      }

      setState(() {
        _providerData = providerData;
        _services = servicesList;
        _reviews = reviewsList;
        _certifications = certificationsList; // Set certifications
        _isLoading = false;

        print('Provider Data: $providerData');
        print('Reviews loaded: ${_reviews.length}');
        print('Reviews field in provider data: ${providerData['reviews']}');
      });
    } catch (e) {
      print('Error loading provider data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading provider data: $e';
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      final DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown date';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown date';
    }
  }

  // Helper methods for URL launcher
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _openMessageScreen() {
    // Get provider name for messaging
    final providerName =
        _providerData != null ? (_providerData!['fullName'] ?? '') : 'Provider';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
            contactName: providerName, providerId: widget.providerId),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Loading provider profile...',
                fontSize: 16,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: _errorMessage,
                fontSize: 16,
                fontFamily: 'Regular',
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProviderData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: TextWidget(
                  text: 'Retry',
                  fontSize: 14,
                  fontFamily: 'Bold',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_providerData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.userSlash,
                color: Colors.grey,
                size: 40,
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Provider not found',
                fontSize: 16,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSliverAppBar(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildProfileHeader(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSecondary.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontFamily: 'Bold',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontFamily: 'Regular',
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Reviews'),
                Tab(text: 'Contact'),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildReviewsTab(),
                  _buildContactTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            TouchableWidget(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: TextWidget(
                  text: 'Provider Profile',
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Extract provider information
    final providerName = _providerData!['fullName'] ?? '';

    final businessName =
        _providerData!['businessName'] ?? 'Professional Services';
    final verified = _providerData!['verified'] as bool? ?? false;
    final experience = _providerData!['experience'] as String? ?? '0 years';
    final rating = (_providerData!['rating'] as num?)?.toDouble() ?? 0.0;
    // Use 'reviews' field instead of 'totalBookings' to show correct number of reviews
    final reviewsCount = (_providerData!['reviews'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              image: _providerData?['profilePicture'] != null
                  ? DecorationImage(
                      image: NetworkImage(
                        _providerData?['profilePicture'],
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: _providerData?['profilePicture'] != null
                ? null
                : Center(
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Name and Verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextWidget(
                text: providerName,
                fontSize: 24,
                fontFamily: 'Bold',
                color: Colors.white,
              ),
              if (verified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.solidCircleCheck,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Business Name
          TextWidget(
            text: businessName,
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white.withOpacity(0.9),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: FontAwesomeIcons.solidStar,
                value: '${rating.toStringAsFixed(1)}',
                label: 'Rating',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: FontAwesomeIcons.commentDots,
                value: '$reviewsCount',
                label: 'Reviews',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: FontAwesomeIcons.calendar,
                value: experience,
                label: 'Experience',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        TextWidget(
          text: value,
          fontSize: 16,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        TextWidget(
          text: label,
          fontSize: 12,
          fontFamily: 'Regular',
          color: Colors.white.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_providerData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Extract provider information
    final about =
        _providerData!['about'] as String? ?? 'No description available';
    final experience =
        '${_providerData!['experience']} years' as String? ?? 'Not specified';
    final serviceArea =
        _providerData!['location'] as String? ?? 'Not specified';
    final availability =
        _providerData!['availability'] as String? ?? 'Not specified';
    final responseTime = '5 minutes';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          _buildSectionCard(
            title: 'About ${_providerData!['firstName'] ?? 'Provider'}',
            icon: FontAwesomeIcons.circleInfo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: about,
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary,
                  maxLines: 10,
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Experience Level', experience),
                _buildInfoRow('Service Area', serviceArea),
                _buildInfoRow('Availability', availability),
                _buildInfoRow('Response Time', responseTime),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Services Offered
          _buildSectionCard(
            title: 'Services Offered',
            icon: FontAwesomeIcons.gear,
            child: _services.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.boxOpen,
                          color: Colors.grey.withOpacity(0.5),
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        TextWidget(
                          text: 'No services available',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                      ],
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _services.map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: TextWidget(
                          text: service['name'] as String,
                          fontSize: 12,
                          fontFamily: 'Medium',
                          color: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          // Certifications
          _buildSectionCard(
            title: 'Certifications & Skills',
            icon: FontAwesomeIcons.award,
            child: _certifications.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.certificate,
                          color: Colors.grey.withOpacity(0.5),
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        TextWidget(
                          text: 'No certifications available',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _certifications.map((certification) {
                      return _buildCertificationItem(
                        certification['name'] as String,
                        certification['issuer'] as String,
                        FontAwesomeIcons.certificate,
                        Colors.blue,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          if (_providerData != null) ...[
            _buildSectionCard(
              title: 'Rating Summary',
              icon: FontAwesomeIcons.chartBar,
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TextWidget(
                                text:
                                    '${(_providerData!['rating'] as num?)?.toDouble() ?? 0.0}',
                                fontSize: 32,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const FaIcon(
                                FontAwesomeIcons.solidStar,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
                          ),
                          TextWidget(
                            text:
                                'Based on ${(_providerData!['reviews'] as num?)?.toInt() ?? 0} reviews',
                            fontSize: 12,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.7),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          _buildRatingBar('5', 0.8),
                          _buildRatingBar('4', 0.6),
                          _buildRatingBar('3', 0.3),
                          _buildRatingBar('2', 0.1),
                          _buildRatingBar('1', 0.05),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Individual Reviews
          ..._reviews.isEmpty
              ? [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.comment,
                          color: Colors.grey.withOpacity(0.5),
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        TextWidget(
                          text: 'No reviews yet',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        TextWidget(
                          text: 'Be the first to review this provider',
                          fontSize: 12,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ]
              : _reviews
                  .map((review) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withOpacity(0.2),
                                            AppColors.primary.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: TextWidget(
                                          text: review['customerName']
                                              .toString()[0],
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextWidget(
                                          text:
                                              review['customerName'].toString(),
                                          fontSize: 14,
                                          fontFamily: 'Bold',
                                          color: AppColors.primary,
                                        ),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return FaIcon(
                                              index <
                                                      (review['rating'] as num)
                                                          .floor()
                                                  ? FontAwesomeIcons.solidStar
                                                  : FontAwesomeIcons.star,
                                              color: Colors.amber,
                                              size: 12,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextWidget(
                                    text: review['service'].toString(),
                                    fontSize: 10,
                                    fontFamily: 'Medium',
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextWidget(
                              text: review['comment'].toString(),
                              fontSize: 13,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: review['date'].toString(),
                              fontSize: 11,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    if (_providerData == null) {
      return const Center(
        child: Text('No contact information available'),
      );
    }

    // Extract contact information
    final phone = _providerData!['phone'] as String? ?? 'Not provided';
    final email = _providerData!['email'] as String? ?? 'Not provided';
    final serviceArea =
        _providerData!['serviceArea'] as String? ?? 'Not specified';
    final availability = _providerData!['availability'] as String? ??
        'Mon-Sun: 8:00 AM - 6:00 PM';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildSectionCard(
            title: 'Quick Actions',
            icon: FontAwesomeIcons.bolt,
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FontAwesomeIcons.phone,
                    label: 'Call',
                    color: Colors.green,
                    onTap: () => _makePhoneCall(phone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FontAwesomeIcons.comment,
                    label: 'Message',
                    color: Colors.blue,
                    onTap: _openMessageScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FontAwesomeIcons.envelope,
                    label: 'Email',
                    color: Colors.orange,
                    onTap: () => _sendEmail(email),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contact Information
          _buildSectionCard(
            title: 'Contact Information',
            icon: FontAwesomeIcons.addressBook,
            child: Column(
              children: [
                _buildContactItem(
                  icon: FontAwesomeIcons.phone,
                  title: 'Phone Number',
                  value: phone,
                  color: Colors.green,
                  onTap: () => _makePhoneCall(phone),
                ),
                _buildContactItem(
                  icon: FontAwesomeIcons.envelope,
                  title: 'Email Address',
                  value: email,
                  color: Colors.blue,
                  onTap: () => _sendEmail(email),
                ),
                _buildContactItem(
                  icon: FontAwesomeIcons.clock,
                  title: 'Working Hours',
                  value: availability,
                  color: Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Emergency Contact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextWidget(
                      text: '24/7 Emergency Service',
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextWidget(
                  text:
                      'For urgent issues, call the emergency hotline below. Available 24 hours a day, 7 days a week.',
                  fontSize: 13,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TouchableWidget(
                  onTap: () => _makePhoneCall('+63 917 123 4567'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.phone,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'Emergency: +63 917 123 4567',
                          fontSize: 14,
                          fontFamily: 'Bold',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
                child: FaIcon(
                  icon,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: title,
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: TextWidget(
              text: '$label:',
              fontSize: 12,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: TextWidget(
              text: value,
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(
    String title,
    String issuer,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  fontSize: 13,
                  fontFamily: 'Bold',
                  color: color,
                ),
                TextWidget(
                  text: issuer,
                  fontSize: 11,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          TextWidget(
            text: stars,
            fontSize: 12,
            fontFamily: 'Medium',
            color: AppColors.onSecondary,
          ),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: label,
              fontSize: 12,
              fontFamily: 'Bold',
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: title,
                    fontSize: 12,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  TextWidget(
                    text: value,
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
