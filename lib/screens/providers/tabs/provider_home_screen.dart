import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../subscreens/provider_notifications_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({Key? key}) : super(key: key);

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Remove hardcoded variables and replace with Firebase data variables
  Map<String, dynamic>? _providerData;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _pendingBookings = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _confirmedBookings = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _completedBookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
    _refreshData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildEarningsSection(),
              _buildQuickStats(),
              _buildCalendarSection(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showChangePhotoDialog,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('providers')
                              .doc(
                                  FirebaseAuth.instance.currentUser?.uid ?? '_')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data!.data() != null) {
                              final data = snapshot.data!.data()!;
                              final profilePicture =
                                  data['profilePicture'] as String?;

                              if (_profileImage != null) {
                                // Show locally selected image
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  child: ClipOval(
                                    child: Image.file(
                                      _profileImage!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              } else if (profilePicture != null &&
                                  profilePicture.isNotEmpty) {
                                // Show image from Firebase Storage
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  child: ClipOval(
                                    child: Image.network(
                                      profilePicture,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Fallback to default icon if image fails to load
                                        return const FaIcon(
                                          FontAwesomeIcons.userTie,
                                          color: AppColors.primary,
                                          size: 20,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            }

                            // Show default icon
                            return CircleAvatar(
                              radius: 25,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: const FaIcon(
                                FontAwesomeIcons.userTie,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Good Day!',
                            fontSize: 16,
                            fontFamily: 'Regular',
                            color: Colors.white.withOpacity(0.9),
                          ),
                          TextWidget(
                            text: _providerData?['fullName'] ?? 'Provider',
                            fontSize: 24,
                            fontFamily: 'Bold',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    TouchableWidget(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderNotificationsScreen(
                              pendingBookings: _pendingBookings,
                              completedBookings: _completedBookings,
                              confirmedBookings: _confirmedBookings,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.bell,
                              color: Colors.white,
                              size: 24,
                            ),
                            if (_pendingBookings.isNotEmpty)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: TextWidget(
                                    text: _pendingBookings.length.toString(),
                                    fontSize: 12,
                                    fontFamily: 'Bold',
                                    color: Colors.white,
                                    align: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStat(
                          FontAwesomeIcons.star,
                          (_providerData?['rating'] ?? 0).toString(),
                          'Rating',
                        ),
                      ),
                      _buildHeaderDivider(),
                      Expanded(
                        child: _buildHeaderStat(
                          FontAwesomeIcons.eye,
                          (_providerData?['reviews'] ?? 0).toString(),
                          'Reviews',
                        ),
                      ),
                      _buildHeaderDivider(),
                      Expanded(
                        child: _buildHeaderStat(
                          FontAwesomeIcons.calendar,
                          _confirmedBookings.length.toString(),
                          'Active Jobs',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 12),
        TextWidget(
          text: value,
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        TextWidget(
          text: label,
          fontSize: 14,
          fontFamily: 'Medium',
          color: Colors.white.withOpacity(0.8),
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildEarningsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.coins,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Earnings Overview',
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildEarningStat(
                    'Today',
                    '₱${_calculateTodayEarnings().toStringAsFixed(0)}',
                    _calculateEarningsChangePercentage(
                        _calculateTodayEarnings(),
                        _calculateYesterdayEarnings()),
                    _calculateTodayEarnings() >= _calculateYesterdayEarnings(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildEarningStat(
                    'This Week',
                    '₱${_calculateWeeklyEarnings().toStringAsFixed(0)}',
                    _calculateEarningsChangePercentage(
                        _calculateWeeklyEarnings(),
                        _calculateLastWeekEarnings()),
                    _calculateWeeklyEarnings() >= _calculateLastWeekEarnings(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningStat(
      String period, String amount, String change, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: period,
          fontSize: 16,
          fontFamily: 'Medium',
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(height: 8),
        TextWidget(
          text: amount,
          fontSize: 28,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FaIcon(
              isPositive
                  ? FontAwesomeIcons.arrowTrendUp
                  : FontAwesomeIcons.arrowTrendDown,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            TextWidget(
              text: change,
              fontSize: 16,
              fontFamily: 'Medium',
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                FontAwesomeIcons.clock,
                _pendingBookings.length.toString(),
                'Pending\nBookings',
                AppColors.secondary,
                () {
                  // Navigate to pending bookings
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                FontAwesomeIcons.userCheck,
                _calculateCompletedToday().toString(),
                'Completed\nToday',
                AppColors.primary.shade600,
                () {
                  // Navigate to completed jobs
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                FontAwesomeIcons.calendar,
                _calculateScheduledTomorrow().toString(),
                'Scheduled\nTomorrow',
                AppColors.primary.shade700,
                () {
                  // Navigate to schedule
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color,
      VoidCallback onTap) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: FaIcon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: count,
              fontSize: 24,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: label,
              fontSize: 12,
              fontFamily: 'Medium',
              color: AppColors.onSecondary.withOpacity(0.7),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.list,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextWidget(
                    text: 'Recent Activity',
                    fontSize: 20,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  TouchableWidget(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecentActivityScreen(
                            pendingBookings: _pendingBookings,
                            completedBookings: _completedBookings,
                            confirmedBookings: _confirmedBookings,
                          ),
                        ),
                      );
                    },
                    child: TextWidget(
                      text: 'View All',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Build recent activity items from Firebase data
            ..._buildRecentActivityItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentActivityItems() {
    final List<Widget> items = [];

    // Add pending bookings
    for (var i = 0; i < _pendingBookings.length && i < 3; i++) {
      final booking = _pendingBookings[i];
      final data = booking.data();
      final serviceName = data['serviceName'] ?? 'Service';
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);

      items.add(
        _buildActivityItem(
          FontAwesomeIcons.userPlus,
          'New booking request',
          '$serviceName • $timeAgo',
          AppColors.secondary,
          true,
        ),
      );
    }

    // Add recent payments (completed bookings)
    for (var i = 0; i < _completedBookings.length && i < 3; i++) {
      final booking = _completedBookings[i];
      final data = booking.data();
      final servicePrice = data['servicePrice'] ?? 0;
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);

      items.add(
        _buildActivityItem(
          FontAwesomeIcons.pesoSign,
          'Payment received',
          '₱$servicePrice • $timeAgo',
          AppColors.primary.shade600,
          false,
        ),
      );
    }

    // If no items, show a message
    if (items.isEmpty) {
      items.add(
        Container(
          padding: const EdgeInsets.all(20),
          child: TextWidget(
            text: 'No recent activity',
            fontSize: 16,
            fontFamily: 'Regular',
            color: AppColors.onSecondary.withOpacity(0.7),
            align: TextAlign.center,
          ),
        ),
      );
    }

    return items;
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';

    final now = DateTime.now();
    final bookingTime = timestamp.toDate();
    final difference = now.difference(bookingTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  Widget _buildActivityItem(
      IconData icon, String title, String subtitle, Color color, bool isNew) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextWidget(
                        text: title,
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: AppColors.primary,
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                TextWidget(
                  text: subtitle,
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final today = DateTime.now();
    final upcomingDates = List.generate(7, (index) {
      return today.add(Duration(days: index));
    });

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.shade600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.calendar,
                      color: AppColors.primary.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextWidget(
                    text: 'This Week\'s Schedule',
                    fontSize: 20,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  TouchableWidget(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(
                              confirmedBookings: _confirmedBookings),
                        ),
                      );
                    },
                    child: TextWidget(
                      text: 'View All',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: AppColors.primary.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingDates.length,
                itemBuilder: (context, index) {
                  final date = upcomingDates[index];
                  final isToday = index == 0;
                  final dayName = [
                    'MON',
                    'TUE',
                    'WED',
                    'THU',
                    'FRI',
                    'SAT',
                    'SUN'
                  ][date.weekday - 1];

                  // Check if there are bookings for this date
                  final hasBooking = _confirmedBookings.any((booking) {
                    final data = booking.data();
                    final timestamp = data['bookingDate'] as Timestamp?;
                    if (timestamp == null) return false;

                    final bookingDate = timestamp.toDate();
                    return bookingDate.year == date.year &&
                        bookingDate.month == date.month &&
                        bookingDate.day == date.day;
                  });

                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    child: TouchableWidget(
                      onTap: () {
                        // Show day details
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.blue
                              : hasBooking
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: hasBooking && !isToday
                              ? Border.all(
                                  color: Colors.orange.withOpacity(0.3))
                              : null,
                        ),
                        child: Column(
                          children: [
                            TextWidget(
                              text: dayName,
                              fontSize: 12,
                              fontFamily: 'Bold',
                              color: isToday
                                  ? Colors.white
                                  : AppColors.onSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text: date.day.toString(),
                              fontSize: 18,
                              fontFamily: 'Bold',
                              color: isToday ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            if (hasBooking)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isToday ? Colors.white : Colors.orange,
                                  shape: BoxShape.circle,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      await Future.wait([
        _fetchProviderData(),
        _fetchPendingBookings(),
        _fetchConfirmedBookings(),
        _fetchCompletedBookings(),
      ]);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error refreshing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProviderData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      // Fetch provider profile data
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _providerData = doc.data();
        });
      } else {
        setState(() {
          _errorMessage = 'Provider profile not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading provider data: $e';
      });
    }
  }

  Future<void> _fetchPendingBookings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Calculate the timestamp for 7 days ago
      final sevenDaysAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('bookingTimestamp', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('bookingTimestamp', descending: true)
          .get();

      setState(() {
        _pendingBookings = snapshot.docs;
      });
    } catch (e) {
      // Handle error silently or log it
      print('Error fetching pending bookings: $e');
    }
  }

  Future<void> _fetchConfirmedBookings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('bookingTimestamp', descending: true)
          .get();

      setState(() {
        _confirmedBookings = snapshot.docs;
      });
    } catch (e) {
      // Handle error silently or log it
      print('Error fetching confirmed bookings: $e');
    }
  }

  Future<void> _fetchCompletedBookings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('bookingTimestamp', descending: true)
          .get();

      setState(() {
        _completedBookings = snapshot.docs;
      });
    } catch (e) {
      // Handle error silently or log it
      print('Error fetching completed bookings: $e');
    }
  }

  double _calculateTodayEarnings() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _completedBookings
        .where((booking) {
          final data = booking.data();
          final timestamp = data['bookingTimestamp'] as Timestamp?;
          if (timestamp == null) return false;

          final bookingDate = timestamp.toDate();
          final bookingDay =
              DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

          return bookingDay == startOfDay;
        })
        .map((booking) => (booking.data()['servicePrice'] as num? ?? 0))
        .fold<num>(0, (sum, price) => sum + price)
        .toDouble();
  }

  double _calculateWeeklyEarnings() {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    return _completedBookings
        .where((booking) {
          final data = booking.data();
          final timestamp = data['bookingTimestamp'] as Timestamp?;
          if (timestamp == null) return false;

          final bookingDate = timestamp.toDate();
          return bookingDate.isAfter(weekAgo) && bookingDate.isBefore(now);
        })
        .map((booking) => (booking.data()['servicePrice'] as num? ?? 0))
        .fold<num>(0, (sum, price) => sum + price)
        .toDouble();
  }

  int _calculateCompletedToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _completedBookings.where((booking) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      if (timestamp == null) return false;

      final bookingDate = timestamp.toDate();
      final bookingDay =
          DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
      return bookingDay == startOfDay;
    }).length;
  }

  int _calculateScheduledTomorrow() {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final startOfTomorrow =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfTomorrow =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    return _confirmedBookings.where((booking) {
      final data = booking.data();
      final timestamp = data['bookingDate'] as Timestamp?;
      if (timestamp == null) return false;

      final bookingDate = timestamp.toDate();
      return bookingDate.isAfter(startOfTomorrow) &&
          bookingDate.isBefore(endOfTomorrow);
    }).length;
  }

  double _calculateYesterdayEarnings() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final startOfYesterday =
        DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfYesterday =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

    return _completedBookings
        .where((booking) {
          final data = booking.data();
          final timestamp = data['bookingTimestamp'] as Timestamp?;
          if (timestamp == null) return false;

          final bookingDate = timestamp.toDate();
          return bookingDate.isAfter(startOfYesterday) &&
              bookingDate.isBefore(endOfYesterday);
        })
        .map((booking) => (booking.data()['servicePrice'] as num? ?? 0))
        .fold<num>(0, (sum, price) => sum + price)
        .toDouble();
  }

  double _calculateLastWeekEarnings() {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    final twoWeeksAgo = now.subtract(Duration(days: 14));

    return _completedBookings
        .where((booking) {
          final data = booking.data();
          final timestamp = data['bookingTimestamp'] as Timestamp?;
          if (timestamp == null) return false;

          final bookingDate = timestamp.toDate();
          return bookingDate.isAfter(twoWeeksAgo) &&
              bookingDate.isBefore(weekAgo);
        })
        .map((booking) => (booking.data()['servicePrice'] as num? ?? 0))
        .fold<num>(0, (sum, price) => sum + price)
        .toDouble();
  }

  String _calculateEarningsChangePercentage(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? '+100%' : '0%';
    }
    final change = ((current - previous) / previous) * 100;
    return change >= 0
        ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'
        : '0%';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        // Upload the image
        await _uploadProfileImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to upload a profile picture.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading profile picture...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('providers')
          .child('$uid.jpg');

      await storageRef.putFile(_profileImage!);
      final downloadURL = await storageRef.getDownloadURL();

      // Update provider document with profile picture URL
      await FirebaseFirestore.instance.collection('providers').doc(uid).update({
        'profilePicture': downloadURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh provider data to show the new profile picture
      await _fetchProviderData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to upload profile picture. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePhotoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildPhotoOption(
                'Take Photo', FontAwesomeIcons.camera, Colors.blue, () {
              _pickImage(ImageSource.camera);
            }),
            _buildPhotoOption(
                'Choose from Gallery', FontAwesomeIcons.images, Colors.green,
                () {
              _pickImage(ImageSource.gallery);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return TouchableWidget(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const SizedBox(width: 16),
            TextWidget(
              text: title,
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// Recent Activity Screen
class RecentActivityScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingBookings;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> completedBookings;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> confirmedBookings;

  const RecentActivityScreen({
    Key? key,
    required this.pendingBookings,
    required this.completedBookings,
    required this.confirmedBookings,
  }) : super(key: key);

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  List<Map<String, dynamic>> get _activities => _getActivitiesFromFirebase();

  List<Map<String, dynamic>> _getActivitiesFromFirebase() {
    final List<Map<String, dynamic>> activities = [];

    String _formatTimeAgo(Timestamp? timestamp) {
      if (timestamp == null) return 'Unknown time';

      final now = DateTime.now();
      final bookingTime = timestamp.toDate();
      final difference = now.difference(bookingTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    }

    // Add pending bookings
    for (var booking in widget.pendingBookings) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final customerName = data['userFullName'] ?? 'Customer';
      final servicePrice = data['servicePrice'] ?? 0;

      activities.add({
        'icon': FontAwesomeIcons.userPlus,
        'title': 'New booking request',
        'subtitle': '$serviceName from $customerName',
        'time': timeAgo,
        'color': AppColors.secondary,
        'isNew': true,
        'amount': '₱$servicePrice',
        'type': 'booking_request',
        'bookingId': booking.id,
      });
    }

    // Add completed bookings (payments)
    for (var booking in widget.completedBookings) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final customerName = data['userFullName'] ?? 'Customer';
      final servicePrice = data['servicePrice'] ?? 0;

      activities.add({
        'icon': FontAwesomeIcons.pesoSign,
        'title': 'Payment received',
        'subtitle': 'From $customerName for $serviceName',
        'time': timeAgo,
        'color': AppColors.primary.shade600,
        'isNew': false,
        'amount': '₱$servicePrice',
        'type': 'payment',
        'bookingId': booking.id,
      });
    }

    // Add confirmed bookings
    for (var booking in widget.confirmedBookings) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final customerName = data['userFullName'] ?? 'Customer';
      final servicePrice = data['servicePrice'] ?? 0;

      activities.add({
        'icon': FontAwesomeIcons.calendarCheck,
        'title': 'Booking confirmed',
        'subtitle': '$serviceName for $customerName',
        'time': timeAgo,
        'color': AppColors.primary.shade700,
        'isNew': false,
        'amount': '₱$servicePrice',
        'type': 'confirmation',
        'bookingId': booking.id,
      });
    }

    // Sort activities by timestamp (most recent first)
    activities.sort((a, b) {
      // This is a simplified sort, in a real implementation you would compare actual timestamps
      return 0; // For now we'll keep the order as is
    });

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Recent Activity',
          fontSize: 24,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: TouchableWidget(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshActivities,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return _buildActivityCard(activity);
          },
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: activity['isNew']
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TouchableWidget(
        onTap: () => _handleActivityTap(activity),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activity['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  activity['icon'],
                  color: activity['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: activity['title'],
                            fontSize: 16,
                            fontFamily: 'Medium',
                            color: AppColors.primary,
                          ),
                        ),
                        if (activity['isNew'])
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: activity['subtitle'],
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextWidget(
                          text: activity['time'],
                          fontSize: 12,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.5),
                        ),
                        if (activity['amount'] != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextWidget(
                              text: activity['amount'],
                              fontSize: 12,
                              fontFamily: 'Bold',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'booking_request':
        _showBookingRequestDialog(activity);
        break;
      case 'review':
        _showReviewDialog(activity);
        break;
      case 'payment':
        _showPaymentDialog(activity);
        break;
      default:
        _showGenericDialog(activity);
    }
  }

  void _showBookingRequestDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.userPlus,
                color: Colors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: 'Booking Request',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: activity['subtitle'],
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            TextWidget(
              text: 'Amount: ${activity['amount']}',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Time: ${activity['time']}',
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to booking details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: TextWidget(
              text: 'View Details',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.star,
                color: Colors.orange,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: 'Customer Review',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: activity['subtitle'],
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            if (activity['review'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextWidget(
                  text: activity['review'],
                  fontSize: 13,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextWidget(
              text: 'Time: ${activity['time']}',
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.pesoSign,
                color: Colors.blue,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: 'Payment Received',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: activity['subtitle'],
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            TextWidget(
              text: 'Amount: ${activity['amount']}',
              fontSize: 16,
              fontFamily: 'Bold',
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Time: ${activity['time']}',
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showGenericDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activity['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                activity['icon'],
                color: activity['color'],
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: activity['title'],
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: activity['subtitle'],
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Time: ${activity['time']}',
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshActivities() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh activities
    });
  }
}

// Calendar Screen
class CalendarScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> confirmedBookings;

  const CalendarScreen({Key? key, required this.confirmedBookings})
      : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late PageController _pageController;

  Map<String, List<Map<String, dynamic>>> _getBookingsFromFirebase() {
    final Map<String, List<Map<String, dynamic>>> bookings = {};

    for (var booking in widget.confirmedBookings) {
      final data = booking.data();
      final timestamp = data['bookingDate'] as Timestamp?;

      if (timestamp != null) {
        final bookingDate = timestamp.toDate();
        final dateKey = _formatDate(bookingDate);

        final bookingData = {
          'time': _formatTime(bookingDate),
          'service': data['serviceName'] ?? 'Service',
          'customer': data['userFullName'] ?? 'Customer',
          'duration': '${data['serviceDuration'] ?? 0} hours',
          'amount': '₱${data['servicePrice'] ?? 0}',
          'status': data['status'] ?? 'confirmed',
          'address': data['address'] ?? 'Address not provided',
          'bookingId': booking.id,
        };

        if (bookings.containsKey(dateKey)) {
          bookings[dateKey]!.add(bookingData);
        } else {
          bookings[dateKey] = [bookingData];
        }
      }
    }

    return bookings;
  }

  Map<String, List<Map<String, dynamic>>> get _bookings =>
      _getBookingsFromFirebase();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Calendar & Schedule',
          fontSize: 24,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: TouchableWidget(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildWeekView(),
          Expanded(
            child: _buildBookingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          TouchableWidget(
            onTap: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.chevronLeft,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: TextWidget(
                text: _getMonthYear(_selectedDate),
                fontSize: 20,
                fontFamily: 'Bold',
                color: Colors.white,
              ),
            ),
          ),
          TouchableWidget(
            onTap: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.chevronRight,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (index) {
      return startOfWeek.add(Duration(days: index));
    });

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: weekDays.map((date) {
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final hasBookings = _hasBookingsOnDate(date);
          final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

          return Expanded(
            child: TouchableWidget(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary.withOpacity(0.3))
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWidget(
                      text: dayName,
                      fontSize: 12,
                      fontFamily: 'Medium',
                      color: isSelected
                          ? Colors.white
                          : AppColors.onSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: date.day.toString(),
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    if (hasBookings)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsList() {
    final dateKey = _formatDate(_selectedDate);
    final bookings = _bookings[dateKey] ?? [];

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.calendarXmark,
                color: AppColors.primary.withOpacity(0.5),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            TextWidget(
              text: 'No bookings scheduled',
              fontSize: 18,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'You have no appointments for this date.',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
              align: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final statusColor = booking['status'] == 'confirmed'
        ? AppColors.secondary
        : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: TouchableWidget(
        onTap: () => _showBookingDetails(booking),
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.clock,
                      color: statusColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: booking['time'],
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                        TextWidget(
                          text: booking['duration'],
                          fontSize: 12,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextWidget(
                      text: booking['status'].toUpperCase(),
                      fontSize: 10,
                      fontFamily: 'Bold',
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextWidget(
                text: booking['service'],
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.user,
                    color: AppColors.onSecondary.withOpacity(0.5),
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  TextWidget(
                    text: booking['customer'],
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary.withOpacity(0.8),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.locationDot,
                    color: AppColors.onSecondary.withOpacity(0.5),
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextWidget(
                      text: booking['address'],
                      fontSize: 12,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    text: booking['amount'],
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: Colors.green,
                  ),
                  if (booking['status'] == 'pending')
                    Row(
                      children: [
                        TouchableWidget(
                          onTap: () => _handleBookingAction(booking, 'decline'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3)),
                            ),
                            child: TextWidget(
                              text: 'Decline',
                              fontSize: 12,
                              fontFamily: 'Bold',
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TouchableWidget(
                          onTap: () => _handleBookingAction(booking, 'accept'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextWidget(
                              text: 'Accept',
                              fontSize: 12,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: 'Booking Details',
          fontSize: 18,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Service:', booking['service']),
            _buildDetailRow('Customer:', booking['customer']),
            _buildDetailRow('Time:', booking['time']),
            _buildDetailRow('Duration:', booking['duration']),
            _buildDetailRow('Amount:', booking['amount']),
            _buildDetailRow('Address:', booking['address']),
            _buildDetailRow('Status:', booking['status'].toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: TextWidget(
              text: label,
              fontSize: 12,
              fontFamily: 'Medium',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          Expanded(
            child: TextWidget(
              text: value,
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBookingAction(Map<String, dynamic> booking, String action) {
    // Handle booking accept/decline
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: action == 'accept' ? 'Accept Booking' : 'Decline Booking',
          fontSize: 18,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: TextWidget(
          text: action == 'accept'
              ? 'Are you sure you want to accept this booking?'
              : 'Are you sure you want to decline this booking?',
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary.withOpacity(0.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                booking['status'] =
                    action == 'accept' ? 'confirmed' : 'declined';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == 'accept' ? AppColors.secondary : AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: TextWidget(
              text: action == 'accept' ? 'Accept' : 'Decline',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _hasBookingsOnDate(DateTime date) {
    final dateKey = _formatDate(date);
    return _bookings.containsKey(dateKey) && _bookings[dateKey]!.isNotEmpty;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
