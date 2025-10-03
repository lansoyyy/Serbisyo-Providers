import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'All'; // All, Booking, Promotions, System

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TextWidget(
                text: 'Filter Notifications',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              ...['All', 'Booking', 'Promotions', 'System'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return TouchableWidget(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          _getFilterIcon(filter),
                          size: 16,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        TextWidget(
                          text: filter,
                          fontSize: 16,
                          fontFamily: isSelected ? 'Bold' : 'Medium',
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSecondary,
                        ),
                        const Spacer(),
                        if (isSelected)
                          FaIcon(
                            FontAwesomeIcons.check,
                            size: 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'All':
        return FontAwesomeIcons.list;
      case 'Booking':
        return FontAwesomeIcons.calendar;
      case 'Promotions':
        return FontAwesomeIcons.tags;
      case 'System':
        return FontAwesomeIcons.gear;
      default:
        return FontAwesomeIcons.bell;
    }
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

    // Sort notifications by timestamp (most recent first)
    // In a real implementation, you would sort by actual timestamps

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

  List<Map<String, dynamic>> _filterNotifications(
      List<Map<String, dynamic>> notifications) {
    if (_selectedFilter == 'All') {
      return notifications;
    } else {
      return notifications
          .where((notification) => notification['type'] == _selectedFilter)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the date 7 days ago
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Enhanced Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Notifications',
                                fontSize: 28,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('bookings')
                                    .where('userId',
                                        isEqualTo: FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '')
                                    .where('bookingTimestamp',
                                        isGreaterThanOrEqualTo:
                                            Timestamp.fromDate(sevenDaysAgo))
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return TextWidget(
                                      text: 'Loading notifications...',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: AppColors.onSecondary
                                          .withOpacity(0.7),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return TextWidget(
                                      text: 'Error loading notifications',
                                      fontSize: 14,
                                      fontFamily: 'Regular',
                                      color: AppColors.onSecondary
                                          .withOpacity(0.7),
                                    );
                                  }

                                  final bookings = snapshot.data?.docs ?? [];
                                  final notifications =
                                      _getAllNotificationsFromFirebase(
                                          bookings);
                                  final filteredNotifications =
                                      _filterNotifications(notifications);
                                  final notificationsCount =
                                      filteredNotifications.length;

                                  return TextWidget(
                                    text: notificationsCount > 0
                                        ? '$notificationsCount notifications'
                                        : 'All caught up!',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color:
                                        AppColors.onSecondary.withOpacity(0.7),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        TouchableWidget(
                          onTap: () {
                            _showNotificationSettings();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.gear,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Filter and Actions Row
                    Row(
                      children: [
                        // Filter Button
                        Expanded(
                          child: TouchableWidget(
                            onTap: _showFilterOptions,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _selectedFilter != 'All'
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.8)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: _selectedFilter != 'All'
                                    ? null
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedFilter != 'All'
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.3),
                                  width: _selectedFilter != 'All' ? 0 : 1.5,
                                ),
                                boxShadow: _selectedFilter != 'All'
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    _getFilterIcon(_selectedFilter),
                                    size: 16,
                                    color: _selectedFilter != 'All'
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text: _selectedFilter,
                                    fontSize: 14,
                                    fontFamily: 'Bold',
                                    color: _selectedFilter != 'All'
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  FaIcon(
                                    FontAwesomeIcons.chevronDown,
                                    size: 12,
                                    color: _selectedFilter != 'All'
                                        ? Colors.white
                                        : AppColors.primary,
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
              // Notifications List
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId',
                          isEqualTo:
                              FirebaseAuth.instance.currentUser?.uid ?? '')
                      .where('bookingTimestamp',
                          isGreaterThanOrEqualTo:
                              Timestamp.fromDate(sevenDaysAgo))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: TextWidget(
                          text: 'Error loading notifications',
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: Colors.red,
                        ),
                      );
                    }

                    final bookings = snapshot.data?.docs ?? [];
                    final notifications =
                        _getAllNotificationsFromFirebase(bookings);
                    final filteredNotifications =
                        _filterNotifications(notifications);

                    return filteredNotifications.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...filteredNotifications
                                    .map((notification) =>
                                        _buildNotificationItem(notification))
                                    .toList(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              FontAwesomeIcons.bellSlash,
              size: 48,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: 'No $_selectedFilter Notifications',
            fontSize: 18,
            fontFamily: 'Bold',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: 'No notifications found for the selected filter.',
            fontSize: 14,
            fontFamily: 'Regular',
            color: AppColors.onSecondary.withOpacity(0.7),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TouchableWidget(
        onTap: () {
          _handleNotificationTap(notification);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Notification Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notification['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notification['color'].withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: FaIcon(
                  notification['icon'],
                  color: notification['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: notification['title'],
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextWidget(
                      text: notification['message'],
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.8),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: notification['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextWidget(
                            text: notification['type'],
                            fontSize: 11,
                            fontFamily: 'Bold',
                            color: notification['color'],
                          ),
                        ),
                        TextWidget(
                          text: notification['time'],
                          fontSize: 12,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.6),
                        ),
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

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Handle notification tap
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final type = notification['type'] as String? ?? 'System';
    final time = notification['time'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: title,
          fontSize: 18,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: message,
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getColorForType(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: '$type • $time',
                fontSize: 12,
                fontFamily: 'Medium',
                color: _getColorForType(type),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Booking':
        return Colors.green;
      case 'Promotions':
        return Colors.orange;
      case 'System':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.onSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextWidget(
                  text: 'Notification Settings',
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                _buildSettingsTile(
                  'Push Notifications',
                  'Receive notifications on your device',
                  FontAwesomeIcons.bell,
                  true,
                ),
                _buildSettingsTile(
                  'Booking Updates',
                  'Get notified about booking status changes',
                  FontAwesomeIcons.calendar,
                  true,
                ),
                _buildSettingsTile(
                  'Promotional Offers',
                  'Receive notifications about deals and offers',
                  FontAwesomeIcons.tags,
                  false,
                ),
                _buildSettingsTile(
                  'System Updates',
                  'Get notified about app updates and news',
                  FontAwesomeIcons.gear,
                  true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              icon,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  fontSize: 15,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 2),
                TextWidget(
                  text: subtitle,
                  fontSize: 13,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.7),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Handle switch toggle
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
