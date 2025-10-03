import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:hanap_raket/widgets/touchable_widget.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../subscreens/message_screen.dart';
import '../subscreens/provider_booking_screen.dart';

class BookingTab extends StatefulWidget {
  const BookingTab({Key? key}) : super(key: key);

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  DateTime? _selectedDate;
  double _currentRating = 0;
  String _selectedStatus = 'All'; // All, Upcoming, Past

  final _reviewController = TextEditingController();

  void _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showStatusDropdown() {
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
                text: 'Filter by Status',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              ...['All', 'Upcoming', 'Past'].map((status) {
                final isSelected = _selectedStatus == status;
                return TouchableWidget(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
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
                          status == 'All'
                              ? FontAwesomeIcons.list
                              : status == 'Upcoming'
                                  ? FontAwesomeIcons.clockRotateLeft
                                  : FontAwesomeIcons.history,
                          size: 16,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        TextWidget(
                          text: status,
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

  void _showRatingDialog(BuildContext context, String provider,
      String bookingId, String providerId) {
    _reviewController.clear();
    _currentRating = 0;

    showDialog(
      context: context,
      builder: (context) {
        double tempRating = 0;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.star,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Rate $provider',
                fontSize: 20,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'How was your service experience?',
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.7),
                align: TextAlign.center,
              ),
            ],
          ),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Star rating
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return TouchableWidget(
                        onTap: () {
                          setState(() {
                            tempRating = index + 1.0;
                            _currentRating = tempRating;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: FaIcon(
                            index < tempRating
                                ? FontAwesomeIcons.solidStar
                                : FontAwesomeIcons.star,
                            color: index < tempRating
                                ? Colors.amber
                                : AppColors.onSecondary.withOpacity(0.3),
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (tempRating > 0) ...[
                  const SizedBox(height: 16),
                  TextWidget(
                    text: _getRatingText(tempRating),
                    fontSize: 16,
                    fontFamily: 'Medium',
                    color: AppColors.primary,
                    align: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                // Review text field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience (optional)',
                      hintStyle: TextStyle(
                        color: AppColors.onSecondary.withOpacity(0.6),
                        fontSize: 14,
                        fontFamily: 'Regular',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TouchableWidget(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextWidget(
                            text: 'Cancel',
                            fontSize: 16,
                            fontFamily: 'Medium',
                            color: AppColors.onSecondary,
                            align: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TouchableWidget(
                        onTap: tempRating > 0
                            ? () {
                                Navigator.pop(context);
                                // Handle rating submission
                                _submitRating(bookingId, provider, providerId,
                                    tempRating, _reviewController.text);
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: tempRating > 0
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: tempRating > 0
                                ? null
                                : AppColors.onSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: tempRating > 0
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: TextWidget(
                            text: 'Submit Rating',
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: tempRating > 0
                                ? Colors.white
                                : AppColors.onSecondary.withOpacity(0.7),
                            align: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        );
      },
    );
  }

  void _submitRating(String bookingId, String provider, String providerId,
      double rating, String review) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Check if booking already has a rating to prevent duplicate ratings
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists && bookingDoc.data()?['rated'] == true) {
        // Show message that booking is already rated
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'This booking has already been rated',
              fontSize: 16,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Create rating document
      final ratingData = {
        'userId': userId,
        'providerName': provider,
        'providerId': providerId,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add rating to Firestore
      await FirebaseFirestore.instance.collection('ratings').add(ratingData);

      // Update booking with rating information
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'rated': true,
        'rating': rating,
        'review': review,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update provider's rating
      if (providerId.isNotEmpty) {
        // Get all ratings for this provider
        final ratingsSnapshot = await FirebaseFirestore.instance
            .collection('ratings')
            .where('providerId', isEqualTo: providerId)
            .get();

        if (ratingsSnapshot.docs.isNotEmpty) {
          // Calculate average rating
          double totalRating = 0;
          for (var doc in ratingsSnapshot.docs) {
            totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
          }
          final averageRating = totalRating / ratingsSnapshot.docs.length;
          final totalReviews = ratingsSnapshot.docs.length;

          // Update provider document with new average rating
          await FirebaseFirestore.instance
              .collection('providers')
              .doc(providerId)
              .update({
            'rating': averageRating,
            'reviews': totalReviews,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Thank you for rating $provider!',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Refresh the UI to hide the rating button
      setState(() {});
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Failed to submit rating: $e',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                      Container(
                        padding: const EdgeInsets.all(12),
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
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.calendarCheck,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'My Bookings',
                              fontSize: 28,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text: 'Manage your service appointments',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Filter buttons row
                  Row(
                    children: [
                      // Date Filter Button
                      Expanded(
                        child: TouchableWidget(
                          onTap: () => _pickDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _selectedDate != null
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color:
                                  _selectedDate != null ? null : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? AppColors.primary
                                    : AppColors.primary.withOpacity(0.3),
                                width: _selectedDate != null ? 0 : 1.5,
                              ),
                              boxShadow: _selectedDate != null
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.25),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.calendarDays,
                                  size: 16,
                                  color: _selectedDate != null
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextWidget(
                                    text: _selectedDate == null
                                        ? 'Filter by Date'
                                        : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                                    fontSize: 14,
                                    fontFamily: 'Bold',
                                    color: _selectedDate != null
                                        ? Colors.white
                                        : AppColors.primary,
                                    maxLines: 1,
                                  ),
                                ),
                                if (_selectedDate != null) ...[
                                  const SizedBox(width: 8),
                                  TouchableWidget(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                    child: FaIcon(
                                      FontAwesomeIcons.xmark,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status Filter Button
                      TouchableWidget(
                        onTap: _showStatusDropdown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _selectedStatus != 'All'
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color:
                                _selectedStatus != 'All' ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedStatus != 'All'
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.3),
                              width: _selectedStatus != 'All' ? 0 : 1.5,
                            ),
                            boxShadow: _selectedStatus != 'All'
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.25),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                _selectedStatus == 'All'
                                    ? FontAwesomeIcons.filter
                                    : _selectedStatus == 'Upcoming'
                                        ? FontAwesomeIcons.clockRotateLeft
                                        : FontAwesomeIcons.history,
                                size: 16,
                                color: _selectedStatus != 'All'
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: _selectedStatus,
                                fontSize: 14,
                                fontFamily: 'Bold',
                                color: _selectedStatus != 'All'
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              FaIcon(
                                FontAwesomeIcons.chevronDown,
                                size: 12,
                                color: _selectedStatus != 'All'
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId',
                        isEqualTo:
                            FirebaseAuth.instance.currentUser?.uid ?? '_')
                    .orderBy('bookingTimestamp', descending: true)
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
                        text: 'Error loading bookings',
                        fontSize: 16,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                              size: 48,
                              color: AppColors.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextWidget(
                            text: 'No Bookings Found',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: 'You haven\'t made any bookings yet.',
                            fontSize: 14,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.7),
                            align: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final allBookings = snapshot.data!.docs
                      .map((doc) => {
                            'id': doc.id,
                            'data': doc.data(),
                          })
                      .toList();

                  // Filter bookings based on selected status
                  List<Map<String, dynamic>> filteredBookings = allBookings;
                  if (_selectedStatus == 'Upcoming') {
                    filteredBookings = allBookings.where((booking) {
                      final data = booking['data'] as Map<String, dynamic>?;
                      if (data == null || data['bookingDate'] == null)
                        return false;
                      return _isBookingUpcoming(data['bookingDate']);
                    }).toList();
                  } else if (_selectedStatus == 'Past') {
                    filteredBookings = allBookings.where((booking) {
                      final data = booking['data'] as Map<String, dynamic>?;
                      if (data == null || data['bookingDate'] == null)
                        return false;
                      return !_isBookingUpcoming(data['bookingDate']);
                    }).toList();
                  }

                  // Filter by selected date if applicable
                  if (_selectedDate != null) {
                    filteredBookings = filteredBookings.where((booking) {
                      final data = booking['data'] as Map<String, dynamic>?;
                      if (data == null || data['bookingDate'] == null)
                        return false;
                      return _isSameDate(data['bookingDate'], _selectedDate!);
                    }).toList();
                  }

                  if (filteredBookings.isEmpty) {
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
                              size: 48,
                              color: AppColors.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextWidget(
                            text: 'No $_selectedStatus Bookings',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text:
                                'No appointments found for the selected filter.',
                            fontSize: 14,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.7),
                            align: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...filteredBookings
                            .map((booking) => _buildBookingCard(
                                  bookingData: booking['data'],
                                  bookingId: booking['id'],
                                ))
                            .toList(),
                        // Add bottom padding for better scrolling experience
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  bool _isBookingUpcoming(dynamic bookingDate) {
    try {
      DateTime date;
      if (bookingDate is Timestamp) {
        date = bookingDate.toDate();
      } else if (bookingDate is String) {
        date = DateTime.parse(bookingDate);
      } else {
        return false;
      }

      // Consider bookings for today or future dates as upcoming
      final now = DateTime.now();
      return date.isAfter(DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  bool _isSameDate(dynamic bookingDate, DateTime selectedDate) {
    try {
      DateTime date;
      if (bookingDate is Timestamp) {
        date = bookingDate.toDate();
      } else if (bookingDate is String) {
        date = DateTime.parse(bookingDate);
      } else {
        return false;
      }

      return date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
    } catch (e) {
      return false;
    }
  }

  Widget _buildBookingCard({
    required Map<String, dynamic> bookingData,
    required String bookingId,
  }) {
    // Extract booking information
    final service = bookingData['serviceName'] ?? 'Service';
    final provider = bookingData['providerFullName'] ?? 'Provider';
    final status = bookingData['status'] ?? 'pending';
    final locationType = bookingData['locationType'] ?? 'Location';
    final paymentMethod = bookingData['paymentMethod'] ?? 'Payment Method';
    final notes = bookingData['notes'] ?? '';
    final providerId = bookingData['providerId'] as String? ?? '';
    final isRated = bookingData['rated'] as bool? ?? false;

    // Format date and time
    String dateStr = 'Date not set';
    String timeStr = 'Time not set';

    try {
      DateTime bookingDateTime;
      if (bookingData['bookingDate'] is Timestamp) {
        bookingDateTime = bookingData['bookingDate'].toDate();
      } else if (bookingData['bookingDate'] is String) {
        bookingDateTime = DateTime.parse(bookingData['bookingDate']);
      } else {
        bookingDateTime = DateTime.now();
      }

      dateStr =
          '${bookingDateTime.month}/${bookingDateTime.day}/${bookingDateTime.year}';
      timeStr =
          '${bookingDateTime.hour}:${bookingDateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Use default values if parsing fails
    }

    // Determine status color
    Color statusColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        icon = FontAwesomeIcons.check;
        break;
      case 'pending':
        statusColor = Colors.orange;
        icon = FontAwesomeIcons.clock;
        break;
      case 'completed':
        statusColor = Colors.blue;
        icon = FontAwesomeIcons.checkCircle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        icon = FontAwesomeIcons.timesCircle;
        break;
      default:
        statusColor = Colors.grey;
        icon = FontAwesomeIcons.questionCircle;
    }

    // Determine if booking is upcoming
    final isUpcoming = _isBookingUpcoming(bookingData['bookingDate']);
    final showRate = status.toLowerCase() == 'completed' && !isRated;
    final canMarkAsCompleted = status.toLowerCase() == 'confirmed';

    return TouchableWidget(
      onTap: () {
        // Handle booking card tap - you can navigate to booking details screen
        // For now, we'll show a simple dialog with booking details
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
                  text: 'Date: $dateStr',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary,
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Time: $timeStr',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary,
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Status: ${status.toUpperCase()}',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: statusColor,
                ),
                if (locationType.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Location: $locationType',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary,
                  ),
                ],
                if (paymentMethod.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Payment: $paymentMethod',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary,
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Notes: $notes',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary,
                  ),
                ],
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
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header section with service info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Service icon with enhanced design
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.briefcase,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    // Status indicator
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Service details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: service,
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      TextWidget(
                        text: provider,
                        fontSize: 14,
                        fontFamily: 'Medium',
                        color: AppColors.onSecondary.withOpacity(0.8),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.calendar,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            TextWidget(
                              text: dateStr,
                              fontSize: 12,
                              fontFamily: 'Medium',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            FaIcon(
                              FontAwesomeIcons.clock,
                              size: 12,
                              color: AppColors.onSecondary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            TextWidget(
                              text: timeStr,
                              fontSize: 12,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextWidget(
                    text: status.toUpperCase(),
                    fontSize: 12,
                    fontFamily: 'Bold',
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons section
          if (isUpcoming || showRate || canMarkAsCompleted) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (canMarkAsCompleted) ...[
                    // Mark as Completed button for confirmed bookings
                    SizedBox(
                      width: double.infinity,
                      child: TouchableWidget(
                        onTap: () => _markBookingAsCompleted(bookingId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.checkCircle,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              TextWidget(
                                text: 'Mark as Completed',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isUpcoming) ...[
                    // Message button for upcoming bookings (full width)
                    SizedBox(
                      width: double.infinity,
                      child: TouchableWidget(
                        onTap: () {
                          Get.to(() => MessageScreen(
                                providerId: providerId,
                                contactName: provider,
                              ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
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
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.message,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              TextWidget(
                                text: 'Message Provider',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showRate) ...[
                    // Rate service and book again buttons for completed bookings
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TouchableWidget(
                              onTap: () => _showRatingDialog(
                                  context, provider, bookingId, providerId),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber,
                                      Colors.amber.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.star,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Rate',
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TouchableWidget(
                              onTap: () {
                                // Navigate to provider booking screen for "Book Again"
                                _bookAgain(provider, providerId, service);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.repeat,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Book Again',
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: AppColors.primary,
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
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  void _bookAgain(String provider, String providerId, String service) {
    try {
      // Navigate to provider booking screen
      Get.to(() => ProviderBookingScreen(
            providerName: provider,
            providerId: providerId,
            initialSelectedService: service,
            rating: 0.0, // Default values
            reviews: 0,
            experience: '',
            verified: false,
            description: '',
          ));
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Failed to navigate to booking screen: $e',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _markBookingAsCompleted(String bookingId) async {
    try {
      // Show a confirmation dialog before marking as completed
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: TextWidget(
            text: 'Mark as Completed',
            fontSize: 20,
            fontFamily: 'Bold',
            color: AppColors.primary,
          ),
          content: TextWidget(
            text: 'Are you sure you want to mark this booking as completed?',
            fontSize: 16,
            fontFamily: 'Regular',
            color: AppColors.onSecondary,
          ),
          actions: [
            TouchableWidget(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextWidget(
                  text: 'Cancel',
                  fontSize: 14,
                  fontFamily: 'Bold',
                  color: AppColors.onSecondary,
                ),
              ),
            ),
            TouchableWidget(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextWidget(
                  text: 'Confirm',
                  fontSize: 14,
                  fontFamily: 'Bold',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldProceed == true) {
        // Update the booking status to 'completed' in Firestore
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Booking marked as completed successfully',
              fontSize: 16,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Failed to mark booking as completed: $e',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
