import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../subscreens/booking_details_screen.dart';
import '../subscreens/provider_chat_screen.dart';

// Add this line for FieldValue
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

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

    // Migrate existing customer data
    _migrateCustomerData();
  }

  // Method to migrate existing bookings' customer data to customers subcollection
  Future<void> _migrateCustomerData() async {
    try {
      final providerId = FirebaseAuth.instance.currentUser?.uid;
      if (providerId == null) return;

      // Check if migration has already been performed
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();

      if (providerDoc.data()?['customersMigrated'] == true) {
        return; // Already migrated
      }

      // Get all bookings for this provider
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: providerId)
          .get();

      if (bookingsSnapshot.docs.isEmpty) return;

      // Group bookings by customer
      final Map<String, List<Map<String, dynamic>>> customerBookings = {};

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';

        if (userId.isNotEmpty) {
          if (!customerBookings.containsKey(userId)) {
            customerBookings[userId] = [];
          }
          customerBookings[userId]!.add(data);
        }
      }

      // Process each customer
      for (var entry in customerBookings.entries) {
        final userId = entry.key;
        final bookings = entry.value;

        if (bookings.isEmpty) continue;

        // Use the most recent booking for customer info
        final latestBooking = bookings.reduce((a, b) {
          final aTimestamp = a['bookingTimestamp'] as Timestamp?;
          final bTimestamp = b['bookingTimestamp'] as Timestamp?;

          if (aTimestamp == null) return b;
          if (bTimestamp == null) return a;

          return aTimestamp.compareTo(bTimestamp) > 0 ? a : b;
        });

        // Calculate total spent
        num totalSpent = 0;
        int completedBookings = 0;
        Timestamp? lastBookingDate;

        for (var booking in bookings) {
          final price = booking['servicePrice'];
          final status = booking['status'] as String? ?? '';
          final timestamp = booking['bookingTimestamp'] as Timestamp?;

          if (status.toLowerCase() == 'completed' && price is num) {
            totalSpent += price;
            completedBookings++;
          }

          if (timestamp != null &&
              (lastBookingDate == null ||
                  timestamp.compareTo(lastBookingDate) > 0)) {
            lastBookingDate = timestamp;
          }
        }

        // Save to customers subcollection
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .collection('customers')
            .doc(userId)
            .set({
          'id': userId,
          'name': latestBooking['userFullName'] ?? 'Customer',
          'email': latestBooking['userEmail'] ?? '',
          'phone': latestBooking['userPhone'] ??
              latestBooking['contactNumber'] ??
              '',
          'totalBookings': completedBookings,
          'totalSpent': totalSpent,
          'avgRating': 5.0, // Default rating
          'lastBookingDate': lastBookingDate ?? FieldValue.serverTimestamp(),
          'createdAt': latestBooking['createdAt'] ??
              latestBooking['bookingTimestamp'] ??
              FieldValue.serverTimestamp(), // Set creation date
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Mark migration as completed
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .update({
        'customersMigrated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error migrating customer data: $e');
    }
  }

  @override
  void dispose() {
    // Dispose of any controllers or resources
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 350,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const FaIcon(
                                    FontAwesomeIcons.clipboardList,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: 'Bookings & Customers',
                                        fontSize: 26,
                                        fontFamily: 'Bold',
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      TextWidget(
                                        text:
                                            'Manage your appointments and clients',
                                        fontSize: 16,
                                        fontFamily: 'Regular',
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildQuickStats(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.clock, size: 20),
                        text: 'Pending',
                      ),
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.playCircle, size: 20),
                        text: 'Active',
                      ),
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.checkCircle, size: 20),
                        text: 'Completed',
                      ),
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.users, size: 20),
                        text: 'Customers',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: SlideTransition(
          position: _slideAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingBookings(),
              _buildActiveBookings(),
              _buildCompletedBookings(),
              _buildCustomersTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: providerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: TextWidget(
                text: 'Error loading stats',
                fontSize: 16,
                fontFamily: 'Regular',
                color: Colors.white,
              ),
            ),
          );
        }

        final bookings = snapshot.data?.docs ?? [];

        // Calculate stats
        int pendingCount = 0;
        int activeCount = 0;
        int completedCount = 0;
        final customers = <String>{};

        for (var doc in bookings) {
          final data = doc.data();
          final status = data['status'] as String? ?? '';
          final customerId = data['userId'] as String? ?? '';

          if (customerId.isNotEmpty) {
            customers.add(customerId);
          }

          switch (status.toLowerCase()) {
            case 'pending':
              pendingCount++;
              break;
            case 'confirmed':
            case 'active':
              activeCount++;
              break;
            case 'completed':
              completedCount++;
              break;
          }
        }

        return Container(
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
                child: _buildStatItem(
                    '$pendingCount', 'Pending', FontAwesomeIcons.clock),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatItem(
                    '$activeCount', 'Active', FontAwesomeIcons.playCircle),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatItem('$completedCount', 'Completed',
                    FontAwesomeIcons.checkCircle),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatItem(
                    '${customers.length}', 'Customers', FontAwesomeIcons.users),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
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
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // Pending Bookings Tab
  Widget _buildPendingBookings() {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by StreamBuilder
      },
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('providerId', isEqualTo: providerId)
            .where('status', isEqualTo: 'pending')
            .orderBy('bookingTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  Icon(
                    FontAwesomeIcons.calendarPlus,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'No pending bookings',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'You have no pending service requests',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final bookingData = bookingDoc.data();
              return _buildBookingCard(bookingData, 'pending', bookingDoc.id);
            },
          );
        },
      ),
    );
  }

  // Active Bookings Tab
  Widget _buildActiveBookings() {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by StreamBuilder
      },
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('providerId', isEqualTo: providerId)
            .where('status', isEqualTo: 'confirmed')
            .orderBy('bookingTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  Icon(
                    FontAwesomeIcons.playCircle,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'No active bookings',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'You have no confirmed service appointments',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final bookingData = bookingDoc.data();
              return _buildBookingCard(bookingData, 'active', bookingDoc.id);
            },
          );
        },
      ),
    );
  }

  // Completed Bookings Tab
  Widget _buildCompletedBookings() {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by StreamBuilder
      },
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('providerId', isEqualTo: providerId)
            .where('status', isEqualTo: 'completed')
            .orderBy('bookingTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  Icon(
                    FontAwesomeIcons.checkCircle,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'No completed bookings',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'You have no completed service appointments',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingData = bookings[index].data();
              return _buildBookingCard(
                  bookingData, 'completed', bookings[index].id);
            },
          );
        },
      ),
    );
  }

  // Customers Tab
  Widget _buildCustomersTab() {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Add a search controller
    final TextEditingController searchController = TextEditingController();
    // Add a ValueNotifier for search query
    final ValueNotifier<String> searchQuery = ValueNotifier<String>('');

    // Add dispose for controller when the widget is removed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      if (context.mounted) {
        searchController.addListener(() {
          searchQuery.value = searchController.text.toLowerCase();
        });
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by StreamBuilder
      },
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .collection('customers')
            .orderBy('lastBookingDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: TextWidget(
                text: 'Error loading customers',
                fontSize: 16,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.users,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'No customers found',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'You have no customer bookings yet',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            );
          }

          final customers = snapshot.data!.docs;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.users,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'No customers found',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'You have no customer bookings yet',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search and filter bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          hintStyle: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          suffixIcon: ValueListenableBuilder<String>(
                            valueListenable: searchQuery,
                            builder: (context, query, _) {
                              return query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        searchController.clear();
                                      },
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                    TouchableWidget(
                      onTap: () {
                        // Show filter options
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.sliders,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Customer stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('providers')
                        .doc(providerId)
                        .collection('customers')
                        .snapshots(),
                    builder: (context, customersSnapshot) {
                      if (!customersSnapshot.hasData) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildCustomerStat('0', 'Total Customers',
                                  AppColors.primary.shade600),
                            ),
                            _buildCustomerStatDivider(),
                            Expanded(
                              child: _buildCustomerStat(
                                  '0', 'Regular Clients', AppColors.secondary),
                            ),
                            _buildCustomerStatDivider(),
                            Expanded(
                              child: _buildCustomerStat('0', 'New This Month',
                                  AppColors.primary.shade700),
                            ),
                          ],
                        );
                      }

                      final allCustomers = customersSnapshot.data!.docs;

                      // Count regular clients (more than 3 bookings)
                      final regularClients = allCustomers.where((customer) {
                        final bookingsCount =
                            customer.data()['totalBookings'] as int? ?? 0;
                        return bookingsCount > 3;
                      }).length;

                      // Count new customers this month
                      final now = DateTime.now();
                      final firstDayOfMonth = DateTime(now.year, now.month, 1);
                      final firstDayTimestamp =
                          Timestamp.fromDate(firstDayOfMonth);

                      final newThisMonth = allCustomers.where((customer) {
                        final createdAt =
                            customer.data()['createdAt'] as Timestamp?;
                        if (createdAt == null) return false;
                        return createdAt.compareTo(firstDayTimestamp) >= 0;
                      }).length;

                      return Row(
                        children: [
                          Expanded(
                            child: _buildCustomerStat(
                                allCustomers.length.toString(),
                                'Total Customers',
                                AppColors.primary.shade600),
                          ),
                          _buildCustomerStatDivider(),
                          Expanded(
                            child: _buildCustomerStat(regularClients.toString(),
                                'Regular Clients', AppColors.secondary),
                          ),
                          _buildCustomerStatDivider(),
                          Expanded(
                            child: _buildCustomerStat(newThisMonth.toString(),
                                'New This Month', AppColors.primary.shade700),
                          ),
                        ],
                      );
                    }),
              ),

              const SizedBox(height: 16),

              // Customer list
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: searchQuery,
                  builder: (context, query, _) {
                    // Filter customers based on search query
                    final filteredCustomers = query.isEmpty
                        ? customers
                        : customers.where((doc) {
                            final data = doc.data();
                            final name =
                                (data['name'] ?? '').toString().toLowerCase();
                            final email =
                                (data['email'] ?? '').toString().toLowerCase();
                            final phone =
                                (data['phone'] ?? '').toString().toLowerCase();

                            return name.contains(query) ||
                                email.contains(query) ||
                                phone.contains(query);
                          }).toList();

                    if (filteredCustomers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.searchMinus,
                              size: 48,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            TextWidget(
                              text: 'No matching customers',
                              fontSize: 18,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: 'Try a different search term',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customerData = filteredCustomers[index].data();
                        return _buildCustomerCard(customerData);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerStat(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(
            FontAwesomeIcons.users,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 12),
        TextWidget(
          text: value,
          fontSize: 22,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        TextWidget(
          text: label,
          fontSize: 14,
          fontFamily: 'Medium',
          color: AppColors.onSecondary.withOpacity(0.7),
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCustomerStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.primary.withOpacity(0.2),
    );
  }

  Widget _buildBookingCard(
      Map<String, dynamic> bookingData, String status, String bookingId) {
    Color statusColor = Colors.grey;
    IconData statusIcon = FontAwesomeIcons.clock;

    switch (status) {
      case 'pending':
        statusColor = AppColors.secondary;
        statusIcon = FontAwesomeIcons.clock;
        break;
      case 'active':
        statusColor = AppColors.primary.shade600;
        statusIcon = FontAwesomeIcons.playCircle;
        break;
      case 'completed':
        statusColor = AppColors.secondary;
        statusIcon = FontAwesomeIcons.checkCircle;
        break;
    }

    // Extract booking information from Firebase data
    final service = bookingData['serviceName'] ?? 'Service';
    final customer = bookingData['userFullName'] ?? 'Customer';
    final price = bookingData['servicePrice'] is num
        ? '₱${(bookingData['servicePrice'] as num).toInt()}'
        : '₱0';

    // Format date and time
    String dateStr = 'Date not set';
    String timeStr = 'Time not set';

    try {
      if (bookingData['bookingDate'] != null) {
        DateTime bookingDateTime;
        if (bookingData['bookingDate'] is Timestamp) {
          bookingDateTime = (bookingData['bookingDate'] as Timestamp).toDate();
        } else if (bookingData['bookingDate'] is String) {
          bookingDateTime = DateTime.parse(bookingData['bookingDate']);
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

    return TouchableWidget(
        onTap: () {
          _showBookingDetails(bookingData, status, statusColor, bookingId);
        },
        child: Container(
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
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        statusIcon,
                        color: statusColor,
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
                                  text: service,
                                  fontSize: 18,
                                  fontFamily: 'Bold',
                                  color: AppColors.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.user,
                                color: AppColors.onSecondary.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              TextWidget(
                                text: customer,
                                fontSize: 16,
                                fontFamily: 'Medium',
                                color: AppColors.onSecondary.withOpacity(0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.calendar,
                                color: AppColors.onSecondary.withOpacity(0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              TextWidget(
                                text: dateStr,
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: AppColors.onSecondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 16),
                              FaIcon(
                                FontAwesomeIcons.clock,
                                color: AppColors.onSecondary.withOpacity(0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              TextWidget(
                                text: timeStr,
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: AppColors.onSecondary.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          TextWidget(
                            text: price,
                            fontSize: 22,
                            fontFamily: 'Bold',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    if (status == 'pending') ...[
                      TouchableWidget(
                        onTap: () {
                          // Decline booking
                          _updateBookingStatus(bookingId, 'cancelled');
                        },
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
                            fontSize: 14,
                            fontFamily: 'Bold',
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TouchableWidget(
                        onTap: () {
                          // Accept booking
                          _updateBookingStatus(bookingId, 'confirmed');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextWidget(
                            text: 'Accept',
                            fontSize: 14,
                            fontFamily: 'Bold',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else if (status == 'active') ...[
                      TouchableWidget(
                        onTap: () {
                          // Navigate to booking details
                          Get.to(() => BookingDetailsScreen(
                                bookingId: bookingId,
                              ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextWidget(
                            text: 'View Details',
                            fontSize: 14,
                            fontFamily: 'Bold',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else if (status == 'completed') ...[
                      // Rating is handled in the booking details screen
                    ],
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  void _showBookingDetails(Map<String, dynamic> bookingData, String status,
      Color statusColor, String bookingId) {
    // Extract booking information from Firebase data
    final service = bookingData['serviceName'] ?? 'Service';
    final customer = bookingData['userFullName'] ?? 'Customer';
    final price = bookingData['servicePrice'] is num
        ? '₱${(bookingData['servicePrice'] as num).toInt()}'
        : '₱0';

    // Format date and time
    String dateStr = 'Date not set';
    String timeStr = 'Time not set';

    try {
      if (bookingData['bookingDate'] != null) {
        DateTime bookingDateTime;
        if (bookingData['bookingDate'] is Timestamp) {
          bookingDateTime = (bookingData['bookingDate'] as Timestamp).toDate();
        } else if (bookingData['bookingDate'] is String) {
          bookingDateTime = DateTime.parse(bookingData['bookingDate']);
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      status == 'pending'
                          ? FontAwesomeIcons.clock
                          : status == 'active'
                              ? FontAwesomeIcons.playCircle
                              : FontAwesomeIcons.checkCircle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextWidget(
                    text: service,
                    fontSize: 24,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookingDetailRow(
                      FontAwesomeIcons.user,
                      'Customer',
                      customer,
                      AppColors.primary.shade600,
                    ),
                    const SizedBox(height: 16),
                    _buildBookingDetailRow(
                      FontAwesomeIcons.calendar,
                      'Date',
                      dateStr,
                      AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                    _buildBookingDetailRow(
                      FontAwesomeIcons.clock,
                      'Time',
                      timeStr,
                      AppColors.primary.shade700,
                    ),
                    const SizedBox(height: 16),
                    _buildBookingDetailRow(
                      FontAwesomeIcons.pesoSign,
                      'Price',
                      price,
                      AppColors.primary.shade800,
                    ),
                    const SizedBox(height: 20),
                    if (status == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TouchableWidget(
                              onTap: () {
                                Navigator.pop(context);
                                // Decline booking
                                _updateBookingStatus(bookingId, 'cancelled');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.xmark,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Decline',
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: AppColors.accent,
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
                                Navigator.pop(context);
                                // Accept booking
                                _updateBookingStatus(bookingId, 'confirmed');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Accept',
                                      fontSize: 14,
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
                    ] else if (status == 'active') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TouchableWidget(
                              onTap: () {
                                Navigator.pop(context);
                                // Message customer logic
                                _messageCustomer(bookingData);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.shade600
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.shade600
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.message,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Message',
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: AppColors.primary,
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
                                Navigator.pop(context);
                                // Navigate to booking details
                                Get.to(() => BookingDetailsScreen(
                                      bookingId: bookingId,
                                    ));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.checkCircle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'View Details',
                                      fontSize: 14,
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
                    ] else if (status == 'completed') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TouchableWidget(
                              onTap: () {
                                Navigator.pop(context);
                                // View customer profile
                                _viewCustomerProfile(bookingData);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.shade600
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.shade600
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.user,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'View Customer',
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
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to update booking status
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      // Get booking document first to access customer ID
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final userId = bookingData['userId'] as String? ?? '';
      final providerId = bookingData['providerId'] as String? ?? '';
      final servicePrice = bookingData['servicePrice'] is num
          ? (bookingData['servicePrice'] as num).toDouble()
          : 0.0;

      // Update booking status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If status is completed, update customer records
      if (newStatus == 'completed' &&
          userId.isNotEmpty &&
          providerId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .collection('customers')
            .doc(userId)
            .set({
          'totalBookings': FieldValue.increment(1),
          'totalSpent': FieldValue.increment(servicePrice),
          'lastBookingDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Booking ${newStatus.toLowerCase()} successfully',
            fontSize: 16,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: newStatus == 'confirmed'
              ? AppColors.secondary
              : (newStatus == 'cancelled'
                  ? AppColors.accent
                  : AppColors.primary),
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

  // Method to message customer
  void _messageCustomer(Map<String, dynamic> bookingData) {
    final customerId = bookingData['userId'] as String? ?? '';
    final customerName = bookingData['userFullName'] as String? ?? 'Customer';

    if (customerId.isNotEmpty) {
      Get.to(() => ProviderChatScreen(
            customerId: customerId,
            customerName: customerName,
          ));
    }
  }

  // Method to view customer profile
  void _viewCustomerProfile(Map<String, dynamic> bookingData) {
    // For now, we'll just show a simple dialog
    final customerName = bookingData['userFullName'] as String? ?? 'Customer';
    final customerPhone = bookingData['contactNumber'] as String? ?? 'N/A';
    final customerEmail = bookingData['userEmail'] as String? ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: TextWidget(
          text: 'Customer Profile',
          fontSize: 20,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: 'Name: $customerName',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Phone: $customerPhone',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Email: $customerEmail',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
          ],
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  }

  Widget _buildBookingDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: label,
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.7),
              ),
              const SizedBox(height: 2),
              TextWidget(
                text: value,
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customerData) {
    // Extract customer information
    final name = customerData['name'] as String? ?? 'Customer';
    final bookingsCount = customerData['totalBookings'] as int? ?? 0;
    final totalSpent = customerData['totalSpent'] as num? ?? 0;
    final avgRating = customerData['avgRating'] as double? ?? 4.5;
    final lastBookingDate = customerData['lastBookingDate'] as Timestamp?;

    // Format last booking date
    String lastBooking = 'No bookings yet';
    if (lastBookingDate != null) {
      try {
        final date = lastBookingDate.toDate();
        lastBooking = '${date.month}/${date.day}/${date.year}';
      } catch (e) {
        lastBooking = 'Date unavailable';
      }
    }

    // Calculate if customer is regular (more than 3 bookings)
    final isRegular = bookingsCount > 3;

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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.shade600.withOpacity(0.1),
              child: TextWidget(
                text: name.isNotEmpty ? name[0].toUpperCase() : 'C',
                fontSize: 22,
                fontFamily: 'Bold',
                color: AppColors.primary,
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
                          text: name,
                          fontSize: 18,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                      ),
                      if (isRegular) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: TextWidget(
                            text: 'Regular',
                            fontSize: 11,
                            fontFamily: 'Bold',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.briefcase,
                        color: AppColors.onSecondary.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: '$bookingsCount bookings',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 16),
                      FaIcon(
                        FontAwesomeIcons.star,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: avgRating.toStringAsFixed(1),
                        fontSize: 14,
                        fontFamily: 'Bold',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendar,
                        color: AppColors.onSecondary.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: 'Last booking: $lastBooking',
                        fontSize: 13,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TouchableWidget(
              onTap: () {
                // View customer details
                _showCustomerDetails(customerData);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.shade600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.eye,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customerData) {
    // Extract customer information
    final name = customerData['name'] as String? ?? 'Customer';
    final bookingsCount = customerData['totalBookings'] as int? ?? 0;
    final totalSpent = customerData['totalSpent'] as num? ?? 0;
    final avgRating = customerData['avgRating'] as double? ?? 4.5;
    final lastBookingDate = customerData['lastBookingDate'] as Timestamp?;
    final customerId = customerData['id'] as String? ?? '';

    // Format last booking date
    String lastBooking = 'No bookings yet';
    if (lastBookingDate != null) {
      try {
        final date = lastBookingDate.toDate();
        lastBooking = '${date.month}/${date.day}/${date.year}';
      } catch (e) {
        lastBooking = 'Date unavailable';
      }
    }

    // Calculate if customer is regular (more than 3 bookings)
    final isRegular = bookingsCount > 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: TextWidget(
                      text: name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      fontSize: 24,
                      fontFamily: 'Bold',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextWidget(
                    text: name,
                    fontSize: 24,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  if (isRegular) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: TextWidget(
                        text: 'Regular Customer',
                        fontSize: 14,
                        fontFamily: 'Bold',
                        color: Colors.green.shade100,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerDetailRow(
                      FontAwesomeIcons.briefcase,
                      'Total Bookings',
                      '$bookingsCount completed',
                      AppColors.primary.shade600,
                    ),
                    const SizedBox(height: 16),
                    _buildCustomerDetailRow(
                      FontAwesomeIcons.star,
                      'Average Rating',
                      '${avgRating.toStringAsFixed(1)}/5.0',
                      AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                    _buildCustomerDetailRow(
                      FontAwesomeIcons.calendar,
                      'Last Booking',
                      lastBooking,
                      AppColors.primary.shade700,
                    ),
                    const SizedBox(height: 16),
                    _buildCustomerDetailRow(
                      FontAwesomeIcons.pesoSign,
                      'Total Spent',
                      '₱${totalSpent.toInt()}',
                      AppColors.primary.shade800,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TouchableWidget(
                            onTap: () {
                              // Message customer
                              if (customerId.isNotEmpty) {
                                Get.to(() => ProviderChatScreen(
                                      customerId: customerId,
                                      customerName: name,
                                    ));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.message,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text: 'Message',
                                    fontSize: 14,
                                    fontFamily: 'Bold',
                                    color: Colors.green,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: label,
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.7),
              ),
              const SizedBox(height: 2),
              TextWidget(
                text: value,
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
