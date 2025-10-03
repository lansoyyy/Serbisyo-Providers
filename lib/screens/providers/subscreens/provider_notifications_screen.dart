import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';

class ProviderNotificationsScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingBookings;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> completedBookings;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> confirmedBookings;

  const ProviderNotificationsScreen({
    Key? key,
    required this.pendingBookings,
    required this.completedBookings,
    required this.confirmedBookings,
  }) : super(key: key);

  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> get allNotifications =>
      _getAllNotificationsFromFirebase();

  // Removed _unreadNotifications list as there's no read/unread functionality

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _loadNotifications();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAllNotificationsFromFirebase() {
    final List<Map<String, dynamic>> notifications = [];

    // Calculate the date 7 days ago
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Filter bookings to only include those from the past 7 days
    final recentPendingBookings = widget.pendingBookings.where((booking) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      if (timestamp == null) return false;
      return timestamp.toDate().isAfter(sevenDaysAgo);
    }).toList();

    final recentCompletedBookings = widget.completedBookings.where((booking) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      if (timestamp == null) return false;
      return timestamp.toDate().isAfter(sevenDaysAgo);
    }).toList();

    final recentConfirmedBookings = widget.confirmedBookings.where((booking) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      if (timestamp == null) return false;
      return timestamp.toDate().isAfter(sevenDaysAgo);
    }).toList();

    // Add pending bookings as booking requests
    for (var booking in recentPendingBookings) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final customerName = data['userFullName'] ?? 'Customer';
      final servicePrice = data['servicePrice'] ?? 0;

      notifications.add({
        'id': booking.id,
        'type': 'booking_request',
        'title': 'New Booking Request',
        'message': '${customerName} requested ${serviceName} service',
        'time': timeAgo,
        // 'isRead': false, // Removed as there's no read/unread functionality
        'icon': FontAwesomeIcons.calendar,
        'color': Colors.blue,
        'actionRequired': true,
        'customerName': customerName,
        'serviceType': serviceName,
        'amount': '₱$servicePrice',
      });
    }

    // Add completed bookings as payment received
    for (var booking in recentCompletedBookings) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final customerName = data['userFullName'] ?? 'Customer';
      final servicePrice = data['servicePrice'] ?? 0;

      notifications.add({
        'id': booking.id,
        'type': 'payment_received',
        'title': 'Payment Received',
        'message':
            'Payment of ₱$servicePrice received from ${customerName} for ${serviceName} service',
        'time': timeAgo,
        // 'isRead': false, // Removed as there's no read/unread functionality
        'icon': FontAwesomeIcons.pesoSign,
        'color': Colors.green,
        'actionRequired': false,
        'amount': '₱$servicePrice',
        'customerName': customerName,
      });
    }

    // Add confirmed bookings as booking confirmed
    for (var booking in recentConfirmedBookings) {
      final data = booking.data();
      final timestamp = data['bookingTimestamp'] as Timestamp?;
      final timeAgo = _formatTimeAgo(timestamp);
      final serviceName = data['serviceName'] ?? 'Service';
      final customerName = data['userFullName'] ?? 'Customer';

      notifications.add({
        'id': booking.id,
        'type': 'booking_confirmed',
        'title': 'Booking Confirmed',
        'message':
            'Your booking with ${customerName} has been confirmed for ${serviceName}',
        'time': timeAgo,
        // 'isRead': true, // Removed as there's no read/unread functionality
        'icon': FontAwesomeIcons.checkCircle,
        'color': Colors.green,
        'actionRequired': false,
        'customerName': customerName,
        'serviceType': serviceName,
      });
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
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  void _loadNotifications() {
    // Notifications are now loaded dynamically from Firebase data
    setState(() {
      // No need to track read/unread status
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Notifications',
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
        actions: [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.bell, size: 18),
                      const SizedBox(width: 8),
                      TextWidget(
                        text: 'Notifications (${allNotifications.length})',
                        fontSize: 16,
                        fontFamily: 'Medium',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationsList(allNotifications),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification);
        },
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
              color: AppColors.primary.withOpacity(0.5),
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          TextWidget(
            text: 'No Notifications',
            fontSize: 22,
            fontFamily: 'Bold',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: 'You\'re all caught up! No new notifications.',
            fontSize: 16,
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
      margin: const EdgeInsets.only(bottom: 12),
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
      ),
      child: TouchableWidget(
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: notification['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(
                      notification['icon'],
                      color: notification['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextWidget(
                                text: notification['title'],
                                fontSize: 18,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: notification['message'],
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.8),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.clock,
                              color: AppColors.onSecondary.withOpacity(0.5),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            TextWidget(
                              text: notification['time'],
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (notification['actionRequired'] == true) ...[
                const SizedBox(height: 12),
                _buildActionButtons(notification),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'booking_request':
        return Row(
          children: [
            Expanded(
              child: TouchableWidget(
                onTap: () => _handleBookingAction(notification, 'decline'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: TextWidget(
                      text: 'Decline',
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TouchableWidget(
                onTap: () => _handleBookingAction(notification, 'accept'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: TextWidget(
                      text: 'Accept',
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'system_update':
        return TouchableWidget(
          onTap: () => _handleSystemUpdate(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: TextWidget(
                text: 'Update Now',
                fontSize: 16,
                fontFamily: 'Bold',
                color: Colors.white,
              ),
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Show detailed notification dialog
    _showNotificationDetail(notification);
  }

  void _showNotificationDetail(Map<String, dynamic> notification) {
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
                color: notification['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                notification['icon'],
                color: notification['color'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: notification['title'],
                fontSize: 20,
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
              text: notification['message'],
              fontSize: 16,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
              maxLines: 10,
            ),
            const SizedBox(height: 12),
            if (notification['customerName'] != null) ...[
              _buildDetailRow('Customer', notification['customerName']),
            ],
            if (notification['serviceType'] != null) ...[
              _buildDetailRow('Service', notification['serviceType']),
            ],
            if (notification['amount'] != null) ...[
              _buildDetailRow('Amount', notification['amount']),
            ],
            if (notification['scheduledDate'] != null) ...[
              _buildDetailRow('Schedule', notification['scheduledDate']),
            ],
            if (notification['reviewText'] != null) ...[
              const SizedBox(height: 8),
              TextWidget(
                text: 'Review:',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextWidget(
                  text: notification['reviewText'],
                  fontSize: 15,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.8),
                  maxLines: 5,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Close',
              fontSize: 16,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: TextWidget(
              text: '$label:',
              fontSize: 14,
              fontFamily: 'Medium',
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ),
          Expanded(
            child: TextWidget(
              text: value,
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBookingAction(Map<String, dynamic> notification, String action) {
    // Handle booking accept/decline
    Navigator.pop(context); // Close any open dialog first

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: action == 'accept' ? 'Accept Booking' : 'Decline Booking',
          fontSize: 20,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: TextWidget(
          text: action == 'accept'
              ? 'Are you sure you want to accept this booking request?'
              : 'Are you sure you want to decline this booking request?',
          fontSize: 16,
          fontFamily: 'Regular',
          color: AppColors.onSecondary.withOpacity(0.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle the action
              setState(() {
                notification['actionRequired'] = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept' ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: TextWidget(
              text: action == 'accept' ? 'Accept' : 'Decline',
              fontSize: 16,
              fontFamily: 'Bold',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSystemUpdate() {
    // Handle system update
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
                FontAwesomeIcons.download,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'App Update',
              fontSize: 20,
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
                  'Update to version 2.1.0 to enjoy new features and improvements.',
              fontSize: 16,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            TextWidget(
              text: 'What\'s New:',
              fontSize: 16,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text:
                  '• Improved booking management\n• Enhanced messaging system\n• Bug fixes and performance improvements',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Later',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle update
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: TextWidget(
              text: 'Update Now',
              fontSize: 16,
              fontFamily: 'Bold',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Reload notifications
    setState(() {
      _loadNotifications();
    });
  }
}
