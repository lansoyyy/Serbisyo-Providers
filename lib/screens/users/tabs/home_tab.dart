import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../subscreens/provider_booking_screen.dart';
import '../subscreens/viewprovider_profile_screen.dart';
import '../subscreens/notification_screen.dart';
import '../subscreens/search_service_screen.dart';
import '../main_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to navigate to services tab
  void _navigateToServicesTab({String? selectedService}) {
    // Navigate to MainScreen with Services tab selected and optional service filter
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialTab: 1, // Services tab index
          serviceCategory: selectedService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header with notification badge
                _buildEnhancedHeader(),
                const SizedBox(height: 24),
                // Enhanced Search Bar with focus animation
                _buildEnhancedSearchBar(),

                const SizedBox(height: 24),
                // Enhanced Promo Card with parallax effect
                _buildEnhancedPromoCard(context),
                const SizedBox(height: 28),
                // Popular Services Section
                _buildPopularServicesSection(),
                const SizedBox(height: 28),
                // Recent Bookings Section
                _buildRecentBookingsSection(),
                const SizedBox(height: 28),
                // Top Rated Providers with enhanced cards
                _buildTopRatedSection(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextWidget(
                    text: 'WELCOME BACK',
                    fontSize: 10,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Serbisyo',
                  fontSize: 32,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                TextWidget(
                  text: 'Connect. Empower. Grow.',
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: () {
              // Calculate the date 7 days ago
              final sevenDaysAgo =
                  DateTime.now().subtract(const Duration(days: 7));
              return FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .where('bookingTimestamp',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
                  .snapshots();
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show notification icon with loading indicator
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.bell, size: 22),
                        color: AppColors.primary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                // Show notification icon without badge on error
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.bell, size: 22),
                        color: AppColors.primary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              final bookings = snapshot.data?.docs ?? [];

              // Calculate notifications count (same logic as in notification screen)
              final notifications = _getAllNotificationsFromFirebase(bookings);
              final notificationsCount = notifications.length;

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.bell, size: 22),
                      color: AppColors.primary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (notificationsCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notificationsCount > 99
                              ? '99+'
                              : notificationsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TouchableWidget(
            onTap: () {
              // Navigate to search screen instead of inline search
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchServiceScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.7), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  TextWidget(
                    text: 'What service do you need?',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                  Expanded(child: const SizedBox(width: 16)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                      child: Center(
                        child: FaIcon(FontAwesomeIcons.sliders,
                            size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Recent Bookings',
                  fontSize: 17,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                TextWidget(
                  text: 'Track your service history',
                  fontSize: 12,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.6),
                ),
              ],
            ),
            TouchableWidget(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(
                      initialTab: 2, // Booking tab index
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextWidget(
                      text: 'View All',
                      fontSize: 12,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    FaIcon(
                      FontAwesomeIcons.chevronRight,
                      color: AppColors.primary,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Real recent bookings from Firebase
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '_')
              .orderBy('bookingTimestamp', descending: true)
              .limit(5) // Limit to 5 most recent bookings
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: TextWidget(
                    text: 'Error loading bookings',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.calendarPlus,
                        size: 32,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'No recent bookings',
                        fontSize: 14,
                        fontFamily: 'Medium',
                        color: AppColors.onSecondary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 4),
                      TextWidget(
                        text: 'Book a service to get started',
                        fontSize: 12,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              );
            }

            final bookings = snapshot.data!.docs;

            return SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: bookings.map((bookingDoc) {
                  final bookingData = bookingDoc.data();

                  // Extract booking information
                  final service = bookingData['serviceName'] ?? 'Service';
                  final provider =
                      bookingData['providerFullName'] ?? 'Provider';
                  final status = bookingData['status'] ?? 'pending';
                  final amount = bookingData['servicePrice'] ?? 0;

                  // Determine status color and icon
                  Color statusColor;
                  IconData statusIcon;

                  switch (status.toLowerCase()) {
                    case 'confirmed':
                      statusColor = Colors.green;
                      statusIcon = FontAwesomeIcons.check;
                      break;
                    case 'pending':
                      statusColor = Colors.orange;
                      statusIcon = FontAwesomeIcons.clock;
                      break;
                    case 'completed':
                      statusColor = Colors.blue;
                      statusIcon = FontAwesomeIcons.checkCircle;
                      break;
                    case 'cancelled':
                      statusColor = Colors.red;
                      statusIcon = FontAwesomeIcons.timesCircle;
                      break;
                    default:
                      statusColor = Colors.grey;
                      statusIcon = FontAwesomeIcons.questionCircle;
                  }

                  return _buildBookingCard(
                    service,
                    status.toUpperCase(),
                    provider,
                    '₱${amount is num ? amount.toInt() : 0}',
                    statusColor,
                    statusIcon,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(
    String service,
    String status,
    String provider,
    String amount,
    Color statusColor,
    IconData statusIcon,
  ) {
    return TouchableWidget(
      onTap: () {
        // Handle booking card tap - show booking details dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: TextWidget(
              text: 'Booking Details',
              fontSize: 20,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Service: $service',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary,
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Provider: $provider',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary,
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Amount: $amount',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextWidget(
                      text: 'Status: ',
                      fontSize: 14,
                      fontFamily: 'Medium',
                      color: AppColors.onSecondary,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            statusIcon,
                            color: statusColor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          TextWidget(
                            text: status,
                            fontSize: 12,
                            fontFamily: 'Bold',
                            color: statusColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TouchableWidget(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextWidget(
                    text: 'Close',
                    fontSize: 14,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextWidget(
                    text: service,
                    fontSize: 14,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        statusIcon,
                        color: statusColor,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: status,
                        fontSize: 10,
                        fontFamily: 'Bold',
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Provider: $provider',
              fontSize: 12,
              fontFamily: 'Medium',
              color: AppColors.onSecondary.withOpacity(0.7),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: amount,
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: AppColors.primary,
                    size: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextWidget(
                    text: 'NEED A SERVICE?',
                    fontSize: 10,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Available Services',
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                TextWidget(
                  text: 'Browse our wide range of professional services',
                  fontSize: 13,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.7),
                ),
              ],
            ),
          ),

          // Service Carousel
          _ServiceCarousel(
            serviceItems: _serviceItems,
            onBookNow: (category) =>
                _navigateToServicesTab(selectedService: category),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Service items data
  final List<Map<String, dynamic>> _serviceItems = [
    {
      'title': 'Mechanic Services',
      'description': 'Professional car repair and maintenance services',
      'icon': FontAwesomeIcons.wrench,
      'color': Colors.blue,
      'category':
          'Maintenance', // Using the correct category that matches ServicesTab
      'image': null, // Placeholder for now
    },
    {
      'title': 'Cleaning Services',
      'description': 'Expert home and office cleaning solutions',
      'icon': FontAwesomeIcons.broom,
      'color': Colors.green,
      'category':
          'Residential', // Using the correct category that matches ServicesTab
      'image': null, // Placeholder for now
    },
    {
      'title': 'Plumbing Services',
      'description': 'Reliable plumbing repairs and installations',
      'icon': FontAwesomeIcons.faucetDrip,
      'color': Colors.cyan,
      'category':
          'Maintenance', // Using the correct category that matches ServicesTab
      'image': null, // Placeholder for now
    },
    {
      'title': 'Electrical Services',
      'description': 'Safe and professional electrical work',
      'icon': FontAwesomeIcons.bolt,
      'color': Colors.amber,
      'category':
          'Maintenance', // Using the correct category that matches ServicesTab
      'image': null, // Placeholder for now
    },
    {
      'title': 'Home Repair',
      'description': 'Complete home maintenance and repair services',
      'icon': FontAwesomeIcons.hammer,
      'color': Colors.orange,
      'category':
          'Residential', // Using the correct category that matches ServicesTab
      'image': null, // Placeholder for now
    },
  ];

  Widget _buildPopularServicesSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextWidget(
                        text: 'POPULAR SERVICES',
                        fontSize: 10,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Popular Services',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    TextWidget(
                      text: 'Most booked services this week',
                      fontSize: 13,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.7),
                    ),
                  ],
                ),
                TouchableWidget(
                  onTap: () {
                    _navigateToServicesTab();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextWidget(
                          text: 'View All',
                          fontSize: 13,
                          fontFamily: 'Bold',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        FaIcon(
                          FontAwesomeIcons.arrowRight,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fetch real services from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('providers')
                .where('applicationStatus', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: TextWidget(
                      text: 'Error loading services',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.red,
                    ),
                  ),
                );
              }

              final providers = snapshot.data?.docs ?? [];

              // Get services from all providers
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getPopularServices(providers),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (futureSnapshot.hasError) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: TextWidget(
                          text: 'Error loading services',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  final services = futureSnapshot.data ?? [];

                  if (services.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.boxOpen,
                              size: 32,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: 'No services available',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 210,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 20),
                      children: services.map((serviceData) {
                        final service =
                            serviceData['service'] as Map<String, dynamic>;
                        final provider =
                            serviceData['provider'] as QueryDocumentSnapshot;
                        final providerData =
                            provider.data() as Map<String, dynamic>;

                        final serviceName =
                            service['name'] as String? ?? 'Service';
                        final price = service['price'] as num? ?? 0;
                        final category =
                            service['category'] as String? ?? 'General';
                        // Use the actual booking count we fetched
                        final bookings =
                            serviceData['bookingCount'] as int? ?? 0;

                        // Get category icon and color
                        IconData icon;
                        Color color;
                        switch (category) {
                          case 'Residential':
                            icon = FontAwesomeIcons.home;
                            color = Colors.blue;
                            break;
                          case 'Commercial':
                            icon = FontAwesomeIcons.building;
                            color = Colors.green;
                            break;
                          case 'Specialized':
                            icon = FontAwesomeIcons.star;
                            color = Colors.orange;
                            break;
                          case 'Maintenance':
                            icon = FontAwesomeIcons.wrench;
                            color = Colors.red;
                            break;
                          default:
                            icon = FontAwesomeIcons.briefcase;
                            color = AppColors.primary;
                        }

                        return _buildServiceCard(
                          serviceName,
                          '₱${price.toInt()}',
                          '$bookings booked',
                          icon,
                          color,
                          category,
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method to get popular services from providers
  Future<List<Map<String, dynamic>>> _getPopularServices(
      List<QueryDocumentSnapshot> providers) async {
    final allServices = <Map<String, dynamic>>[];

    // Limit to first 10 providers to avoid performance issues
    final limitedProviders =
        providers.length > 10 ? providers.sublist(0, 10) : providers;

    for (final provider in limitedProviders) {
      try {
        // Get up to 5 services per provider
        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .doc(provider.id)
            .collection('services')
            .limit(5)
            .get();

        for (final serviceDoc in servicesSnapshot.docs) {
          // Get actual booking count for this service from bookings collection
          final serviceData = serviceDoc.data();
          final serviceName = serviceData['name'] as String? ?? 'Service';

          // Query bookings collection for this specific service and provider
          final bookingQuery = await FirebaseFirestore.instance
              .collection('bookings')
              .where('providerId', isEqualTo: provider.id)
              .where('serviceName', isEqualTo: serviceName)
              .get();

          final bookingCount = bookingQuery.docs.length;

          allServices.add({
            'service': serviceData,
            'provider': provider,
            'bookingCount': bookingCount, // Add actual booking count
          });

          // Limit to 10 services total
          if (allServices.length >= 10) {
            return allServices;
          }
        }
      } catch (e) {
        print('Error fetching services for provider ${provider.id}: $e');
      }
    }

    return allServices;
  }

  Widget _buildServiceCard(String title, String price, String bookings,
      IconData icon, Color color, String serviceCategory) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TouchableWidget(
        onTap: () {
          _navigateToServicesTab(selectedService: serviceCategory);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: FaIcon(icon, color: color, size: 24),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green,
                          Colors.green.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextWidget(
                      text: 'Popular',
                      fontSize: 10,
                      fontFamily: 'Bold',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: title,
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: price,
                fontSize: 16,
                fontFamily: 'Bold',
                color: color,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.book,
                    color: AppColors.onSecondary.withOpacity(0.5),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  TextWidget(
                    text: bookings,
                    fontSize: 12,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRatedSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextWidget(
                        text: 'TOP RATED',
                        fontSize: 10,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: 'Top Rated Providers',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    TextWidget(
                      text: 'Trusted by 10,000+ customers',
                      fontSize: 13,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fetch real providers from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('providers')
                .where('applicationStatus', isEqualTo: 'approved')
                .orderBy('rating', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 340,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 340,
                  child: Center(
                    child: TextWidget(
                      text: 'Error loading providers',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: Colors.red,
                    ),
                  ),
                );
              }

              final providers = snapshot.data?.docs ?? [];

              if (providers.isEmpty) {
                return SizedBox(
                  height: 340,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.users,
                          size: 32,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        TextWidget(
                          text: 'No providers available',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 320,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  children: providers.map((providerDoc) {
                    final data = providerDoc.data() as Map<String, dynamic>;

                    // Extract provider information
                    final firstName =
                        (data['firstName'] ?? data['fullName'] ?? 'Provider')
                            .toString();
                    final lastName = (data['lastName'] ?? '').toString();
                    final providerName = lastName.isNotEmpty
                        ? '$firstName $lastName'
                        : firstName;
                    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                    final totalBookings =
                        (data['reviews'] as num?)?.toInt() ?? 0;
                    final experience =
                        (data['experience'] ?? 'Professional').toString();
                    final verified = (data['verified'] as bool?) ?? false;
                    final description =
                        (data['about'] ?? 'Professional service provider')
                            .toString();

                    return _buildProviderCard(
                      name: providerName,
                      rating: rating,
                      reviews: totalBookings,
                      experience: experience,
                      verified: verified,
                      description: description,
                      context: context,
                      providerId: providerDoc.id,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String name,
    required double rating,
    required int reviews,
    required String experience,
    required bool verified,
    required String description,
    required BuildContext context,
    required String providerId,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TouchableWidget(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProviderProfileScreen(
                providerId: providerId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced provider image section
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('providers')
                        .doc(providerId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data = snapshot.data!.data()!;
                        final profilePicture =
                            data['profilePicture'] as String?;

                        if (profilePicture != null &&
                            profilePicture.isNotEmpty) {
                          // Show image from Firebase Storage
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: Image.network(
                              profilePicture,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to default icon if image fails to load
                                return Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.user,
                                    color: AppColors.primary,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      }

                      // Show default icon
                      return Center(
                        child: FaIcon(
                          FontAwesomeIcons.user,
                          color: AppColors.primary,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
                if (verified)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and distance section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: name.split(' ')[0],
                          fontSize: 18,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.15),
                              Colors.amber.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.solidStar,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            TextWidget(
                              text: rating > 0
                                  ? rating.toStringAsFixed(1)
                                  : 'N/A',
                              fontSize: 12,
                              fontFamily: 'Bold',
                              color: AppColors.onSecondary,
                              maxLines: 1,
                            ),
                            TextWidget(
                              text: ' ($reviews reviews)',
                              fontSize: 10,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Rating section with enhanced design

                  const SizedBox(height: 10),
                  // Experience section
                  TextWidget(
                    text: '$experience years experience',
                    fontSize: 12,
                    fontFamily: 'Medium',
                    color: Colors.black,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: TouchableWidget(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderBookingScreen(
                              providerId: providerId,
                              providerName: name,
                              rating: rating,
                              reviews: reviews,
                              experience: experience,
                              verified: verified,
                              description: description,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextWidget(
                              text: 'Book Now',
                              fontSize: 14,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const FaIcon(
                              FontAwesomeIcons.arrowRight,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllNotificationsFromFirebase(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    final List<Map<String, dynamic>> notifications = [];

    // Add booking notifications
    for (var booking in bookings) {
      final data = booking.data()!;
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final providerName = data['providerFullName'] ?? 'Provider';
      final servicePrice = data['servicePrice'] ?? 0;
      final status = data['status'] ?? 'pending';

      // Create different notifications based on booking status
      switch (status) {
        case 'pending':
          notifications.add({
            'id': booking.id,
            'type': 'Booking',
            'title': 'Booking Request Sent',
            'message':
                'Your request for $serviceName with $providerName is pending confirmation',
            'time': timeAgo,
            'icon': FontAwesomeIcons.clock,
            'color': Colors.amber,
            'bookingId': booking.id,
            'serviceName': serviceName,
            'providerName': providerName,
          });
          break;
        case 'confirmed':
          notifications.add({
            'id': booking.id,
            'type': 'Booking',
            'title': 'Booking Confirmed',
            'message':
                'Your $serviceName appointment with $providerName has been confirmed',
            'time': timeAgo,
            'icon': FontAwesomeIcons.calendarCheck,
            'color': Colors.green,
            'bookingId': booking.id,
            'serviceName': serviceName,
            'providerName': providerName,
          });
          break;
        case 'completed':
          notifications.add({
            'id': booking.id,
            'type': 'Booking',
            'title': 'Service Completed',
            'message':
                'Your $serviceName service with $providerName has been completed',
            'time': timeAgo,
            'icon': FontAwesomeIcons.checkCircle,
            'color': Colors.blue,
            'bookingId': booking.id,
            'serviceName': serviceName,
            'providerName': providerName,
          });
          notifications.add({
            'id': '${booking.id}_payment',
            'type': 'Booking',
            'title': 'Payment Processed',
            'message':
                'Payment of ₱$servicePrice for $serviceName has been processed',
            'time': timeAgo,
            'icon': FontAwesomeIcons.creditCard,
            'color': Colors.green,
            'bookingId': booking.id,
            'amount': '₱$servicePrice',
          });
          break;
        case 'cancelled':
          notifications.add({
            'id': booking.id,
            'type': 'Booking',
            'title': 'Booking Cancelled',
            'message':
                'Your $serviceName appointment with $providerName has been cancelled',
            'time': timeAgo,
            'icon': FontAwesomeIcons.timesCircle,
            'color': Colors.red,
            'bookingId': booking.id,
            'serviceName': serviceName,
            'providerName': providerName,
          });
          break;
      }
    }

    return notifications;
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';

    final now = DateTime.now();
    final bookingTime = timestamp.toDate();
    final difference = now.difference(bookingTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}

// Separate widget for the service carousel to prevent rebuilding other sections
class _ServiceCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> serviceItems;
  final Function(String) onBookNow;

  const _ServiceCarousel({
    Key? key,
    required this.serviceItems,
    required this.onBookNow,
  }) : super(key: key);

  @override
  State<_ServiceCarousel> createState() => _ServiceCarouselState();
}

class _ServiceCarouselState extends State<_ServiceCarousel> {
  late PageController _pageController;
  late Timer _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoSlideTimer.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < widget.serviceItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; // Loop back to the first item
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildPlaceholderImage(IconData icon, Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: FaIcon(
          icon,
          color: color,
          size: 60,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: widget.serviceItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final service = widget.serviceItems[index];
                return TouchableWidget(
                  onTap: () {
                    widget.onBookNow(service['category']);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Service Image (placeholder)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                            child: service['image'] != null
                                ? Image.asset(
                                    service['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage(
                                          service['icon'], service['color']);
                                    },
                                  )
                                : _buildPlaceholderImage(
                                    service['icon'], service['color']),
                          ),
                          // Gradient Overlay
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Service Details
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: FaIcon(
                                          service['icon'],
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextWidget(
                                          text: service['title'],
                                          fontSize: 18,
                                          fontFamily: 'Bold',
                                          color: Colors.white,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  TextWidget(
                                    text: service['description'],
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.white.withOpacity(0.9),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.serviceItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
