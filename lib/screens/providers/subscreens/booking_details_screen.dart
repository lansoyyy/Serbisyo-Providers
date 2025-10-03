import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import 'provider_chat_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
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

    _animationController.forward();
    _fetchBookingData();
  }

  Future<void> _fetchBookingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (doc.exists) {
        setState(() {
          _bookingData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Booking not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading booking: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get statusColor {
    if (_bookingData == null) return Colors.grey;

    final status = _bookingData!['status'] as String? ?? 'pending';

    switch (status) {
      case 'pending':
        return AppColors.secondary;
      case 'confirmed':
      case 'active':
        return AppColors.primary;
      case 'completed':
        return AppColors.secondary;
      case 'cancelled':
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    if (_bookingData == null) return FontAwesomeIcons.clock;

    final status = _bookingData!['status'] as String? ?? 'pending';

    switch (status) {
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'confirmed':
      case 'active':
        return FontAwesomeIcons.playCircle;
      case 'completed':
        return FontAwesomeIcons.checkCircle;
      case 'cancelled':
        return FontAwesomeIcons.timesCircle;
      default:
        return FontAwesomeIcons.clock;
    }
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
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Loading booking details...',
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
                FontAwesomeIcons.exclamationTriangle,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: _errorMessage,
                fontSize: 16,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
              ),
              const SizedBox(height: 16),
              TouchableWidget(
                onTap: _fetchBookingData,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextWidget(
                    text: 'Retry',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookingData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.fileInvoice,
                size: 48,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'No booking data available',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    final status = _bookingData!['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150,
              floating: false,
              pinned: true,
              backgroundColor: statusColor,
              leading: TouchableWidget(
                onTap: () => Get.back(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: _bookingData!['serviceName']
                                            as String? ??
                                        'Service',
                                    fontSize: 24,
                                    fontFamily: 'Bold',
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: TextWidget(
                                      text: status.toUpperCase(),
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: Colors.white,
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
                ),
              ),
            ),
          ];
        },
        body: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Map Section
                _buildMapSection(),
                const SizedBox(height: 20),

                // Booking Information
                _buildBookingInfoSection(),
                const SizedBox(height: 20),

                // Customer Information
                _buildCustomerInfoSection(),
                const SizedBox(height: 20),

                // Service Details
                _buildServiceDetailsSection(),
                const SizedBox(height: 20),

                // Payment Information
                _buildPaymentInfoSection(),
                const SizedBox(height: 20),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.secondary;
      case 'confirmed':
      case 'active':
        return AppColors.primary;
      case 'completed':
        return AppColors.secondary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMapSection() {
    final address = _bookingData!['address'] as String? ?? '';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.locationDot,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Service Location',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      if (address.isNotEmpty)
                        TextWidget(
                          text: address,
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                      if (address.isEmpty)
                        TextWidget(
                          text: 'Address not provided',
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Map Placeholder
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Stack(
              children: [
                // Grid pattern to simulate map
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: MapGridPainter(),
                ),
                // Location marker
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.locationDot,
                        color: Colors.red,
                        size: 30,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Service Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBookingInfoSection() {
    // Format date and time
    String dateStr = 'Date not set';
    String timeStr = 'Time not set';

    try {
      if (_bookingData!['bookingDate'] != null) {
        DateTime bookingDateTime;
        if (_bookingData!['bookingDate'] is Timestamp) {
          bookingDateTime =
              (_bookingData!['bookingDate'] as Timestamp).toDate();
        } else if (_bookingData!['bookingDate'] is String) {
          bookingDateTime = DateTime.parse(_bookingData!['bookingDate']);
        } else {
          bookingDateTime = DateTime.now();
        }

        dateStr =
            '${bookingDateTime.month}/${bookingDateTime.day}/${bookingDateTime.year}';
        timeStr =
            '${bookingDateTime.hour}:${bookingDateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Use default values if parsing fails
    }

    final notes = _bookingData!['notes'] as String? ?? '';
    final serviceDuration = _bookingData!['serviceDuration'] as String? ?? '';

    return Container(
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
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.clipboardList,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Booking Information',
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              FontAwesomeIcons.calendar,
              'Date & Time',
              '$dateStr at $timeStr',
              AppColors.primary.shade600,
            ),
            const SizedBox(height: 12),
            if (serviceDuration.isNotEmpty)
              _buildInfoRow(
                FontAwesomeIcons.clock,
                'Duration',
                serviceDuration,
                Colors.orange,
              ),
            const SizedBox(height: 12),
            _buildInfoRow(
              FontAwesomeIcons.idCard,
              'Booking ID',
              widget.bookingId,
              AppColors.primary.shade700,
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                FontAwesomeIcons.noteSticky,
                'Special Instructions',
                notes,
                AppColors.primary.shade800,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    final customerName = _bookingData!['userFullName'] as String? ?? 'Customer';
    final customerPhone = _bookingData!['contactNumber'] as String? ?? '';
    final customerEmail = _bookingData!['userEmail'] as String? ?? '';
    final userId = _bookingData!['userId'] as String? ?? '';

    return Container(
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.user,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Customer Information',
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: TextWidget(
                    text: customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : 'C',
                    fontSize: 20,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: customerName,
                        fontSize: 20,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                      Row(
                        children: [
                          if (customerPhone.isNotEmpty)
                            TouchableWidget(
                              onTap: () {
                                // Call customer
                                _makePhoneCall(customerPhone);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.phone,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                              ),
                            ),
                          if (customerPhone.isNotEmpty)
                            const SizedBox(width: 8),
                          TouchableWidget(
                            onTap: () {
                              // Navigate to chat screen
                              if (userId.isNotEmpty) {
                                Get.to(() => ProviderChatScreen(
                                      customerId: userId,
                                      customerName: customerName,
                                    ));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.message,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customerPhone.isNotEmpty)
              _buildInfoRow(
                FontAwesomeIcons.phone,
                'Phone Number',
                customerPhone,
                AppColors.secondary,
              ),
            if (customerPhone.isEmpty)
              _buildInfoRow(
                FontAwesomeIcons.phone,
                'Phone Number',
                'Not provided',
                AppColors.onSecondary.withOpacity(0.5),
              ),
            const SizedBox(height: 12),
            if (customerEmail.isNotEmpty)
              _buildInfoRow(
                FontAwesomeIcons.envelope,
                'Email Address',
                customerEmail,
                AppColors.primary.shade600,
              ),
            if (customerEmail.isEmpty)
              _buildInfoRow(
                FontAwesomeIcons.envelope,
                'Email Address',
                'Not provided',
                AppColors.onSecondary.withOpacity(0.5),
              ),
            const SizedBox(height: 12),
            // Previous bookings would require a separate query, showing placeholder for now
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsSection() {
    final serviceName = _bookingData!['serviceName'] as String? ?? 'Service';
    final serviceDescription =
        _bookingData!['serviceDescription'] as String? ?? '';

    return Container(
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
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.tools,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Service Details',
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              FontAwesomeIcons.broom,
              'Service Type',
              serviceName,
              AppColors.primary.shade600,
            ),
            if (serviceDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                FontAwesomeIcons.list,
                'Description',
                serviceDescription,
                AppColors.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoSection() {
    final servicePrice = _bookingData!['servicePrice'] is num
        ? (_bookingData!['servicePrice'] as num).toInt()
        : 0;
    final platformFee = _bookingData!['platformFee'] is num
        ? (_bookingData!['platformFee'] as num).toInt()
        : 20;
    final totalPrice = servicePrice + platformFee;
    final paymentMethod = _bookingData!['paymentMethod'] as String? ?? 'Cash';
    final status = _bookingData!['status'] as String? ?? 'pending';

    return Container(
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.pesoSign,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Payment Information',
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Service Fee',
                        fontSize: 16,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary,
                      ),
                      TextWidget(
                        text: '₱$servicePrice',
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: AppColors.onSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Platform Fee',
                        fontSize: 16,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary,
                      ),
                      TextWidget(
                        text: '₱$platformFee',
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: AppColors.onSecondary,
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Total Amount',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: Colors.green,
                      ),
                      TextWidget(
                        text: '₱$totalPrice',
                        fontSize: 20,
                        fontFamily: 'Bold',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              FontAwesomeIcons.creditCard,
              'Payment Method',
              paymentMethod,
              AppColors.primary.shade600,
            ),
          ],
        ),
      ),
    );
  }

  // Make phone call using URL launcher
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Could not launch phone app',
              fontSize: 16,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error making call: $e',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: label,
                fontSize: 14,
                fontFamily: 'Medium',
                color: AppColors.onSecondary.withOpacity(0.7),
              ),
              const SizedBox(height: 2),
              TextWidget(
                text: value,
                fontSize: 16,
                fontFamily: 'Regular',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Method to update booking status
  Future<void> _updateBookingStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the booking data
      _fetchBookingData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Booking updated successfully',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Failed to update booking: $e',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }
}

// Custom painter for map grid pattern
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
