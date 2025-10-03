import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  // Signup service definitions (matching the signup screen)
  final List<Map<String, dynamic>> _signupAvailableServices = [
    // Residential Services
    {
      'name': 'Regular House Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.house,
      'color': Colors.blue,
      'defaultDescription': 'Weekly or bi-weekly house cleaning service',
      'defaultPrice': 1500,
      'defaultDuration': '2-3 hours'
    },
    {
      'name': 'Deep Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.broom,
      'color': Colors.purple,
      'defaultDescription': 'Comprehensive deep cleaning service',
      'defaultPrice': 3000,
      'defaultDuration': '4-6 hours'
    },
    {
      'name': 'Move-in/out Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.boxOpen,
      'color': Colors.orange,
      'defaultDescription': 'Cleaning for moving in or out',
      'defaultPrice': 2500,
      'defaultDuration': '3-5 hours'
    },
    {
      'name': 'Post-Construction Cleaning',
      'category': 'Residential',
      'icon': FontAwesomeIcons.hammer,
      'color': Colors.brown,
      'defaultDescription': 'Cleaning after construction or renovation',
      'defaultPrice': 4000,
      'defaultDuration': '5-8 hours'
    },

    // Commercial Services
    {
      'name': 'Office Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.building,
      'color': Colors.green,
      'defaultDescription': 'Professional office cleaning service',
      'defaultPrice': 2000,
      'defaultDuration': '2-4 hours'
    },
    {
      'name': 'Retail Space Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.store,
      'color': Colors.blue,
      'defaultDescription': 'Cleaning for retail and commercial spaces',
      'defaultPrice': 2500,
      'defaultDuration': '3-5 hours'
    },
    {
      'name': 'Restaurant Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.utensils,
      'color': Colors.red,
      'defaultDescription': 'Specialized restaurant cleaning service',
      'defaultPrice': 3000,
      'defaultDuration': '3-6 hours'
    },
    {
      'name': 'Medical Facility Cleaning',
      'category': 'Commercial',
      'icon': FontAwesomeIcons.hospital,
      'color': Colors.teal,
      'defaultDescription': 'Sanitized medical facility cleaning',
      'defaultPrice': 3500,
      'defaultDuration': '4-6 hours'
    },

    // Specialized Services
    {
      'name': 'Carpet Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.rug,
      'color': Colors.red,
      'defaultDescription': 'Professional carpet cleaning service',
      'defaultPrice': 1800,
      'defaultDuration': '1-3 hours'
    },
    {
      'name': 'Window Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.windowMaximize,
      'color': Colors.cyan,
      'defaultDescription': 'Interior and exterior window cleaning',
      'defaultPrice': 1200,
      'defaultDuration': '1-2 hours'
    },
    {
      'name': 'Upholstery Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.couch,
      'color': Colors.indigo,
      'defaultDescription': 'Furniture and upholstery deep cleaning',
      'defaultPrice': 2000,
      'defaultDuration': '2-4 hours'
    },
    {
      'name': 'Pressure Washing',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.sprayCan,
      'color': Colors.lime,
      'defaultDescription': 'High-pressure exterior cleaning',
      'defaultPrice': 2500,
      'defaultDuration': '2-4 hours'
    },
    {
      'name': 'Pool Cleaning',
      'category': 'Specialized',
      'icon': FontAwesomeIcons.water,
      'color': Colors.blue,
      'defaultDescription': 'Swimming pool cleaning and maintenance',
      'defaultPrice': 1500,
      'defaultDuration': '1-2 hours'
    },

    // Maintenance Services
    {
      'name': 'Plumbing',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.wrench,
      'color': Colors.blue,
      'defaultDescription': 'Plumbing repair and maintenance services',
      'defaultPrice': 1800,
      'defaultDuration': '1-3 hours'
    },
    {
      'name': 'Electrical Work',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.bolt,
      'color': Colors.yellow,
      'defaultDescription': 'Electrical installation and repair',
      'defaultPrice': 2000,
      'defaultDuration': '1-4 hours'
    },
    {
      'name': 'HVAC Services',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.fan,
      'color': Colors.green,
      'defaultDescription': 'Air conditioning and heating services',
      'defaultPrice': 2500,
      'defaultDuration': '2-4 hours'
    },
    {
      'name': 'Appliance Repair',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.screwdriver,
      'color': Colors.grey,
      'defaultDescription': 'Home appliance repair services',
      'defaultPrice': 1500,
      'defaultDuration': '1-2 hours'
    },
    {
      'name': 'Landscaping',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.leaf,
      'color': Colors.green,
      'defaultDescription': 'Garden and landscape maintenance',
      'defaultPrice': 2000,
      'defaultDuration': '2-6 hours'
    },
    {
      'name': 'Pest Control',
      'category': 'Maintenance',
      'icon': FontAwesomeIcons.bug,
      'color': Colors.brown,
      'defaultDescription': 'Pest control and extermination services',
      'defaultPrice': 1800,
      'defaultDuration': '1-3 hours'
    },
  ];

  @override
  void initState() {
    super.initState();
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
    _ensureProviderDataExists();
  }

  Future<void> _ensureProviderDataExists() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();

      if (!providerDoc.exists || providerDoc.data()?['createdAt'] == null) {
        await FirebaseFirestore.instance.collection('providers').doc(uid).set({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'applicationStatus': 'approved',
        }, SetOptions(merge: true));
      }

      // Migrate signup services to subcollection structure
      final servicesCollection = FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('services');

      final servicesSnapshot = await servicesCollection.get();

      // Check if services need to be migrated from signup
      if (servicesSnapshot.docs.isEmpty) {
        final providerData = providerDoc.data();
        final signupCategories =
            List<String>.from(providerData?['serviceCategories'] ?? []);

        if (signupCategories.isNotEmpty) {
          // Migrate categories from signup selection
          for (final categoryName in signupCategories) {
            await FirebaseFirestore.instance
                .collection('providers')
                .doc(uid)
                .collection('serviceCategories')
                .doc(categoryName.toLowerCase())
                .set({
              'name': categoryName,
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // Clear the old categories array after migration
          await FirebaseFirestore.instance
              .collection('providers')
              .doc(uid)
              .update({
            'serviceCategories': [],
            'categoriesMigrated': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Add default categories if none exist
          final defaultCategories = ['Residential', 'Commercial'];

          for (final categoryName in defaultCategories) {
            await FirebaseFirestore.instance
                .collection('providers')
                .doc(uid)
                .collection('serviceCategories')
                .doc(categoryName.toLowerCase())
                .set({
              'name': categoryName,
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  void dispose() {
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
              expandedHeight: 500,
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
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(),
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
                    isScrollable: true,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.user, size: 16),
                        text: 'About',
                      ),
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.briefcase, size: 16),
                        text: 'Services',
                      ),
                      Tab(
                        icon: FaIcon(FontAwesomeIcons.star, size: 16),
                        text: 'Reviews',
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
              _buildAboutTab(),
              _buildServicesTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .snapshots(),
      builder: (context, snapshot) {
        final authUser = FirebaseAuth.instance.currentUser;
        String displayName = authUser?.displayName ?? 'Provider';
        String businessName = 'Professional Services';
        String email = authUser?.email ?? '';

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data()!;
          final firstName = (data['firstName'] ?? '').toString().trim();
          final lastName = (data['lastName'] ?? '').toString().trim();
          final business = (data['businessName'] ?? '').toString().trim();
          final docEmail = (data['email'] ?? '').toString().trim();

          final combined =
              [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();
          if (combined.isNotEmpty) displayName = combined;
          if (business.isNotEmpty) businessName = business;
          if (docEmail.isNotEmpty) email = docEmail;
        }

        return Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('providers')
                        .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data = snapshot.data!.data()!;
                        final profilePicture =
                            data['profilePicture'] as String?;

                        if (_profileImage != null) {
                          // Show locally selected image
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            child: ClipOval(
                              child: Image.file(
                                _profileImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else if (profilePicture != null &&
                            profilePicture.isNotEmpty) {
                          // Show image from Firebase Storage
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            child: ClipOval(
                              child: Image.network(
                                profilePicture,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to default icon if image fails to load
                                  return const FaIcon(
                                    FontAwesomeIcons.userTie,
                                    color: Colors.white,
                                    size: 40,
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      }

                      // Show default icon
                      return const Center(
                        child: FaIcon(
                          FontAwesomeIcons.userTie,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: TouchableWidget(
                    onTap: () {
                      _showChangePhotoDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: displayName,
              fontSize: 26,
              fontFamily: 'Bold',
              color: Colors.white,
            ),

            const SizedBox(height: 8),
            TextWidget(
              text: businessName,
              fontSize: 16,
              fontFamily: 'Regular',
              color: Colors.white.withOpacity(0.9),
              align: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Provider Statistics
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('providerId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '_')
                  .snapshots(),
              builder: (context, bookingsSnapshot) {
                if (bookingsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildEnhancedStat('...', 'Total\nBookings',
                            FontAwesomeIcons.calendarCheck),
                        _buildStatDivider(),
                        _buildEnhancedStat(
                            '...', 'Rating', FontAwesomeIcons.star),
                        _buildStatDivider(),
                        _buildEnhancedStat(
                            '...', 'Earnings', FontAwesomeIcons.pesoSign),
                      ],
                    ),
                  );
                }

                // Calculate provider statistics
                final totalBookings = bookingsSnapshot.data?.docs.length ?? 0;

                // Calculate average rating from completed bookings
                double averageRating = 0.0;
                double totalEarnings = 0.0;

                if (bookingsSnapshot.hasData) {
                  final completedBookings = bookingsSnapshot.data!.docs
                      .where((doc) => doc.data()['status'] == 'completed')
                      .toList();

                  if (completedBookings.isNotEmpty) {
                    // Calculate average rating
                    final ratingsData = completedBookings
                        .where((doc) => doc.data()['rating'] != null)
                        .toList();

                    if (ratingsData.isNotEmpty) {
                      final totalRating = ratingsData
                          .map(
                              (doc) => (doc.data()['rating'] as num).toDouble())
                          .reduce((a, b) => a + b);
                      averageRating = totalRating / ratingsData.length;
                    }

                    // Calculate total earnings
                    totalEarnings = completedBookings
                        .map((doc) =>
                            (doc.data()['servicePrice'] as num?)?.toDouble() ??
                            0.0)
                        .reduce((a, b) => a + b);
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEnhancedStat(totalBookings.toString(),
                          'Total\nBookings', FontAwesomeIcons.calendarCheck),
                      _buildStatDivider(),
                      _buildEnhancedStat(
                          averageRating > 0
                              ? averageRating.toStringAsFixed(1)
                              : 'N/A',
                          'Rating',
                          FontAwesomeIcons.star),
                      _buildStatDivider(),
                      _buildEnhancedStat(
                          totalEarnings > 0
                              ? '₱${totalEarnings.toStringAsFixed(0)}'
                              : '₱0',
                          'Earnings',
                          FontAwesomeIcons.pesoSign),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextWidget(
          text: value,
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        TextWidget(
          text: label,
          fontSize: 11,
          fontFamily: 'Medium',
          color: Colors.white.withOpacity(0.8),
          align: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildContactCard(),
          const SizedBox(height: 16),
          _buildExperienceCard(),
          const SizedBox(height: 16),
          _buildCertificationsCard(),
          const SizedBox(height: 16),
          _buildAccountSettingsCard(),
          const SizedBox(height: 16),
          _buildSupportCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .snapshots(),
      builder: (context, snapshot) {
        String aboutText =
            'Professional service provider with years of experience. I provide high-quality services with attention to detail and customer satisfaction.';

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data()!;
          aboutText = (data['about'] ?? aboutText).toString();
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.circleInfo,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: 'About Me',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                  ),
                  TouchableWidget(
                    onTap: () {
                      _showEditAboutDialog(aboutText);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: aboutText,
                fontSize: 16,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.8),
                maxLines: 10,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .snapshots(),
      builder: (context, snapshot) {
        final authUser = FirebaseAuth.instance.currentUser;
        String phone = '—';
        String email = authUser?.email ?? '—';
        String location = '—';
        String availability = 'Mon-Sat, 8:00 AM - 6:00 PM';

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data()!;
          phone = (data['phone'] ?? '—').toString();
          email = (data['email'] ?? email).toString();
          location = (data['location'] ?? '—').toString();
          availability = (data['availability'] ?? availability).toString();
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.addressBook,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: 'Contact Information',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                  ),
                  TouchableWidget(
                    onTap: () {
                      _showEditContactDialog(
                          phone, email, location, availability);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildContactItem(
                FontAwesomeIcons.phone,
                'Phone',
                phone,
                AppColors.primary.shade600,
              ),
              _buildContactItem(
                FontAwesomeIcons.envelope,
                'Email',
                email,
                Colors.orange,
              ),
              _buildContactItem(
                FontAwesomeIcons.locationDot,
                'Location',
                location,
                AppColors.accent,
              ),
              _buildContactItem(
                FontAwesomeIcons.clock,
                'Available',
                availability,
                AppColors.secondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactItem(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
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
                  text: label,
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary.withOpacity(0.6),
                ),
                const SizedBox(height: 2),
                TextWidget(
                  text: value,
                  fontSize: 16,
                  fontFamily: 'Medium',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .collection('experience')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final experiences = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.shade600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.briefcase,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: 'Experience',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                  ),
                  TouchableWidget(
                    onTap: () {
                      _showAddExperienceDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.shade600.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.plus,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (experiences.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.briefcase,
                          size: 32,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        TextWidget(
                          text: 'No experience added yet',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text:
                              'Add your work experience to showcase your expertise',
                          fontSize: 12,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.5),
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...experiences.map((doc) {
                  final data = doc.data();
                  return _buildExperienceItem(
                    data['position'] ?? 'Position',
                    data['company'] ?? 'Company',
                    data['duration'] ?? 'Duration',
                    data['description'] ?? 'Description',
                    doc.id,
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExperienceItem(String position, String company, String duration,
      String description, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: position,
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditExperienceDialog(
                          docId, position, company, duration, description);
                      break;
                    case 'delete':
                      _showDeleteExperienceDialog(docId, position);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextWidget(
                text: company,
                fontSize: 14,
                fontFamily: 'Medium',
                color: AppColors.primary.shade600,
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              TextWidget(
                text: duration,
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: description,
            fontSize: 14,
            fontFamily: 'Regular',
            color: AppColors.onSecondary.withOpacity(0.7),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .collection('certifications')
          .orderBy('year', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final certifications = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.certificate,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: 'Certifications',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                  ),
                  TouchableWidget(
                    onTap: () {
                      _showAddCertificationDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.plus,
                        color: Colors.orange,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (certifications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.certificate,
                          size: 32,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        TextWidget(
                          text: 'No certifications added yet',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Add your certifications to build credibility',
                          fontSize: 12,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.5),
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...certifications.map((doc) {
                  final data = doc.data();
                  return _buildCertificationItem(
                    data['name'] ?? 'Certification',
                    data['year'] ?? 'Year',
                    doc.id,
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertificationItem(String name, String year, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const FaIcon(
              FontAwesomeIcons.award,
              color: Colors.orange,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextWidget(
              text: name,
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ),
          TextWidget(
            text: year,
            fontSize: 14,
            fontFamily: 'Medium',
            color: AppColors.onSecondary.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditCertificationDialog(docId, name, year);
                  break;
                case 'delete':
                  _showDeleteCertificationDialog(docId, name);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.more_vert,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Container(
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
          color: AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.gear,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Account Settings',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          // Section Content
          _buildMenuTile(
            FontAwesomeIcons.userPen,
            'Edit Profile',
            'Update your personal information',
            () => _showEditProviderProfileDialog(),
          ),

          _buildMenuTile(
            FontAwesomeIcons.rightFromBracket,
            'Logout',
            'Sign out of this device',
            () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
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
          color: AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.headset,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Support',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          // Section Content

          _buildMenuTile(
            FontAwesomeIcons.headset,
            'Contact Support',
            'Call or email our support team',
            () => _contactSupport(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                    fontFamily: 'Medium',
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
            FaIcon(
              FontAwesomeIcons.chevronRight,
              color: AppColors.primary.withOpacity(0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .collection('serviceCategories')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: 'Failed to load categories',
                  fontSize: 16,
                  fontFamily: 'Medium',
                  color: Colors.red,
                ),
              ],
            ),
          );
        }

        final categories = snapshot.data?.docs ?? [];

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: 'No service categories yet',
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Add categories from your signup selection',
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.7),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: categories
                .map((categoryDoc) => _buildCategorySection(categoryDoc))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(
      QueryDocumentSnapshot<Map<String, dynamic>> categoryDoc) {
    final categoryData = categoryDoc.data();
    final categoryName = categoryData['name'] as String? ?? 'Category';
    final isActive = categoryData['isActive'] as bool? ?? true;

    // Get category icon and color
    IconData categoryIcon;
    Color categoryColor;

    switch (categoryName) {
      case 'Residential':
        categoryIcon = FontAwesomeIcons.house;
        categoryColor = Colors.blue;
        break;
      case 'Commercial':
        categoryIcon = FontAwesomeIcons.building;
        categoryColor = Colors.green;
        break;
      case 'Specialized':
        categoryIcon = FontAwesomeIcons.star;
        categoryColor = Colors.orange;
        break;
      case 'Maintenance':
        categoryIcon = FontAwesomeIcons.wrench;
        categoryColor = Colors.red;
        break;
      default:
        categoryIcon = FontAwesomeIcons.briefcase;
        categoryColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          color: categoryColor.withOpacity(0.2),
          width: 1,
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
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  categoryIcon,
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextWidget(
                  text: categoryName,
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
              if (!isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextWidget(
                    text: 'Inactive',
                    fontSize: 10,
                    fontFamily: 'Bold',
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 8),
              TouchableWidget(
                onTap: () {
                  _showAddServiceDialog(categoryName);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.plus,
                    color: categoryColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategoryServices(categoryName),
        ],
      ),
    );
  }

  Widget _buildCategoryServices(String categoryName) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
          .collection('services')
          .where('category', isEqualTo: categoryName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final services = snapshot.data?.docs ?? [];

        if (services.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    FontAwesomeIcons.briefcase,
                    size: 32,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'No services in this category yet',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: 'Tap the + button to add services',
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.5),
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: services
              .map((serviceDoc) => _buildFirebaseServiceItem(serviceDoc))
              .toList(),
        );
      },
    );
  }

  Widget _buildFirebaseServiceItem(
      QueryDocumentSnapshot<Map<String, dynamic>> serviceDoc) {
    final service = serviceDoc.data();
    final name = service['name'] as String? ?? 'Service';
    final description = service['description'] as String? ?? 'No description';
    final price = service['price'] as num? ?? 0;
    final duration = service['duration'] as String? ?? 'Duration not specified';
    final isActive = service['isActive'] as bool? ?? true;
    final category = service['category'] as String? ?? 'General Services';

    // Get icon from stored data or use default
    IconData serviceIcon = FontAwesomeIcons.briefcase;
    if (service['iconCodePoint'] != null) {
      serviceIcon = IconData(
        service['iconCodePoint'] as int,
        fontFamily: service['iconFontFamily'] as String?,
      );
    } else {
      // Try to match with signup services for legacy data
      final signupService = _signupAvailableServices.firstWhere(
        (s) => s['name'] == name,
        orElse: () => {'icon': FontAwesomeIcons.briefcase},
      );
      serviceIcon = signupService['icon'] as IconData;
    }

    // Get color from stored data or use default
    Color serviceColor = AppColors.primary;
    if (service['colorValue'] != null) {
      serviceColor = Color(service['colorValue'] as int);
    } else {
      // Try to match with signup services for legacy data
      final signupService = _signupAvailableServices.firstWhere(
        (s) => s['name'] == name,
        orElse: () => {'color': AppColors.primary},
      );
      serviceColor = signupService['color'] as Color;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.background : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? serviceColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextWidget(
                        text: name,
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: isActive ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextWidget(
                          text: 'Inactive',
                          fontSize: 10,
                          fontFamily: 'Bold',
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                TextWidget(
                  text: description,
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color:
                      AppColors.onSecondary.withOpacity(isActive ? 0.7 : 0.5),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: serviceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextWidget(
                    text: category,
                    fontSize: 11,
                    fontFamily: 'Medium',
                    color: serviceColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextWidget(
                text: '₱${price.toStringAsFixed(0)}',
                fontSize: 16,
                fontFamily: 'Bold',
                color: isActive ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 2),
              TextWidget(
                text: duration,
                fontSize: 12,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(isActive ? 0.5 : 0.3),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle':
                  _toggleServiceStatus(serviceDoc.id, !isActive);
                  break;
                case 'delete':
                  _showDeleteServiceDialog(serviceDoc.id, name);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                    const SizedBox(width: 8),
                    Text(isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.more_vert,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategory(
      String title, List<Map<String, dynamic>> services) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: title,
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
              TouchableWidget(
                onTap: () {
                  _showAddServiceDialog(title);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.plus,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...services.map((service) => _buildServiceItem(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: service['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              service['icon'],
              color: service['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: service['name'],
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                TextWidget(
                  text: service['description'],
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: AppColors.onSecondary.withOpacity(0.7),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextWidget(
                text: service['price'],
                fontSize: 16,
                fontFamily: 'Bold',
                color: Colors.green,
              ),
              const SizedBox(height: 2),
              TextWidget(
                text: service['duration'],
                fontSize: 12,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '_')
          .where('status', isEqualTo: 'completed')
          .where('rating', isGreaterThan: 0)
          .orderBy('rating', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final reviews = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildReviewsHeader(reviews),
              const SizedBox(height: 20),
              if (reviews.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Icon(
                        FontAwesomeIcons.star,
                        size: 64,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      TextWidget(
                        text: 'No reviews yet',
                        fontSize: 18,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Complete your first booking to receive reviews',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary.withOpacity(0.7),
                        align: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final reviewData = reviews[index].data();
                    return _buildReviewItem(reviewData);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsHeader(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> reviews) {
    double averageRating = 0.0;
    Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (reviews.isNotEmpty) {
      // Calculate average rating
      double totalRating = 0;
      for (final review in reviews) {
        final rating = (review.data()['rating'] as num?)?.toInt() ?? 0;
        totalRating += rating;
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      }
      averageRating = totalRating / reviews.length;
    }

    final totalReviews = reviews.length;

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextWidget(
                      text: averageRating > 0
                          ? averageRating.toStringAsFixed(1)
                          : '0.0',
                      fontSize: 36,
                      fontFamily: 'Bold',
                      color: Colors.orange,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return FaIcon(
                            FontAwesomeIcons.solidStar,
                            color: index < averageRating.round()
                                ? Colors.orange
                                : Colors.grey.withOpacity(0.3),
                            size: 20,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text:
                          '$totalReviews Review${totalReviews != 1 ? 's' : ''}',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildRatingBar(5, ratingCounts[5] ?? 0, totalReviews),
                    _buildRatingBar(4, ratingCounts[4] ?? 0, totalReviews),
                    _buildRatingBar(3, ratingCounts[3] ?? 0, totalReviews),
                    _buildRatingBar(2, ratingCounts[2] ?? 0, totalReviews),
                    _buildRatingBar(1, ratingCounts[1] ?? 0, totalReviews),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          TextWidget(
            text: '$stars',
            fontSize: 14,
            fontFamily: 'Medium',
            color: AppColors.onSecondary.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextWidget(
            text: '$count',
            fontSize: 14,
            fontFamily: 'Medium',
            color: AppColors.onSecondary.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = review['userFullName'] ?? 'Anonymous User';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['review'] ?? 'No comment provided';
    final serviceName = review['serviceName'] ?? 'Service';

    // Format the date
    String dateText = 'Recently';
    if (review['createdAt'] != null) {
      final completedAt = (review['createdAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(completedAt).inDays;

      if (difference == 0) {
        dateText = 'Today';
      } else if (difference == 1) {
        dateText = '1 day ago';
      } else if (difference < 7) {
        dateText = '$difference days ago';
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        dateText = '$weeks week${weeks != 1 ? 's' : ''} ago';
      } else {
        final months = (difference / 30).floor();
        dateText = '$months month${months != 1 ? 's' : ''} ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: TextWidget(
                  text: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: userName,
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return FaIcon(
                              FontAwesomeIcons.solidStar,
                              color: index < rating
                                  ? Colors.orange
                                  : Colors.grey.withOpacity(0.3),
                              size: 10,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: dateText,
                          fontSize: 12,
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
          const SizedBox(height: 12),
          TextWidget(
            text: comment,
            fontSize: 15,
            fontFamily: 'Regular',
            color: AppColors.onSecondary.withOpacity(0.8),
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextWidget(
              text: serviceName,
              fontSize: 12,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // The working add service dialog implementation is below

  void _showEditAboutDialog(String currentAbout) {
    final TextEditingController aboutController =
        TextEditingController(text: currentAbout);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Edit About Me',
                fontSize: 20,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: aboutController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'About Me Description',
                    hintText:
                        'Describe your professional background, experience, and services...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Please sign in to update your profile.',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .update({
                          'about': aboutController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TextWidget(
                                text: 'About me updated successfully!',
                                fontSize: 14,
                                fontFamily: 'Medium',
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text:
                                  'Failed to update profile. Please try again.',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: isSaving ? 'Saving...' : 'Save',
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

  void _showEditContactDialog(String currentPhone, String currentEmail,
      String currentLocation, String currentAvailability) {
    final TextEditingController phoneController =
        TextEditingController(text: currentPhone == '—' ? '' : currentPhone);
    final TextEditingController emailController =
        TextEditingController(text: currentEmail == '—' ? '' : currentEmail);
    final TextEditingController locationController = TextEditingController(
        text: currentLocation == '—' ? '' : currentLocation);
    final TextEditingController availabilityController =
        TextEditingController(text: currentAvailability);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.addressBook,
                  color: AppColors.secondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Edit Contact Information',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+63 912 345 6789',
                    prefixIcon: const Icon(FontAwesomeIcons.phone, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your.email@gmail.com',
                    prefixIcon: const Icon(FontAwesomeIcons.envelope, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'City, Province',
                    prefixIcon:
                        const Icon(FontAwesomeIcons.locationDot, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: availabilityController,
                  decoration: InputDecoration(
                    labelText: 'Availability',
                    hintText: 'Mon-Sat, 8:00 AM - 6:00 PM',
                    prefixIcon: const Icon(FontAwesomeIcons.clock, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text:
                                  'Please sign in to update contact information.',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .update({
                          'phone': phoneController.text.trim(),
                          'email': emailController.text.trim(),
                          'location': locationController.text.trim(),
                          'availability': availabilityController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TextWidget(
                                text:
                                    'Contact information updated successfully!',
                                fontSize: 14,
                                fontFamily: 'Medium',
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Failed to update contact information.',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: isSaving ? 'Saving...' : 'Save',
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

  void _showAddExperienceDialog() {
    final positionController = TextEditingController();
    final companyController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.briefcase,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Add Experience',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: positionController,
                  decoration: InputDecoration(
                    labelText: 'Position Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyController,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration (e.g., 2020 - Present)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      if (positionController.text.trim().isEmpty ||
                          companyController.text.trim().isEmpty ||
                          durationController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please fill in all required fields.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .collection('experience')
                            .add({
                          'position': positionController.text.trim(),
                          'company': companyController.text.trim(),
                          'duration': durationController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'startDate': DateTime.now(), // For ordering
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Experience added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to add experience.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: isSaving ? 'Adding...' : 'Add',
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

  void _showAddServiceDialog(String category) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    String selectedCategory = category;
    Map<String, dynamic>? selectedSignupService;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  FontAwesomeIcons.briefcase,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextWidget(
                  text: 'Add Service to $category',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Service type selection
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'Choose Service Type:',
                          fontSize: 14,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedSignupService,
                          decoration: InputDecoration(
                            hintText: 'Select predefined or create custom',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<Map<String, dynamic>>(
                              value: null,
                              child: Text('Custom Service'),
                            ),
                            ..._signupAvailableServices
                                .where((service) =>
                                    service['category'] == selectedCategory)
                                .map((service) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: service,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(
                                      service['icon'] as IconData,
                                      size: 16,
                                      color: service['color'] as Color,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        service['name'] as String,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedSignupService = value;
                              if (value != null) {
                                nameController.text = value['name'] as String;
                                descController.text =
                                    value['defaultDescription'] as String;
                                priceController.text =
                                    value['defaultPrice'].toString();
                                durationController.text =
                                    value['defaultDuration'] as String;
                              } else {
                                nameController.clear();
                                descController.clear();
                                priceController.clear();
                                durationController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Service Name',
                      hintText: 'e.g., Regular House Cleaning',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Service Description',
                      hintText: 'Brief description of the service',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            hintText: '1,500',
                            prefixText: '₱ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          decoration: InputDecoration(
                            labelText: 'Duration',
                            hintText: '2-3 hours',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty ||
                          descController.text.trim().isEmpty ||
                          priceController.text.trim().isEmpty ||
                          durationController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to add a service.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final serviceData = {
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'category': selectedCategory,
                          'price': double.tryParse(
                                  priceController.text.replaceAll(',', '')) ??
                              0,
                          'duration': durationController.text.trim(),
                          'isActive': true,
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        // Add icon and color data if from signup service
                        if (selectedSignupService != null) {
                          final icon =
                              selectedSignupService!['icon'] as IconData;
                          final color =
                              selectedSignupService!['color'] as Color;
                          serviceData['iconCodePoint'] = icon.codePoint;
                          serviceData['iconFontFamily'] =
                              icon.fontFamily ?? 'FontAwesome';
                          serviceData['colorValue'] = color.value;
                        } else {
                          // Default icon and color for custom services
                          serviceData['iconCodePoint'] =
                              FontAwesomeIcons.briefcase.codePoint;
                          serviceData['iconFontFamily'] =
                              FontAwesomeIcons.briefcase.fontFamily ??
                                  'FontAwesome';
                          serviceData['colorValue'] = AppColors.primary.value;
                        }

                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .collection('services')
                            .add(serviceData);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Service added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Failed to add service. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: isSaving ? 'Adding...' : 'Add Service',
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

  void _showAddCertificationDialog() {
    final nameController = TextEditingController();
    final yearController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  FontAwesomeIcons.certificate,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Add Certification',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Certification Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                decoration: InputDecoration(
                  labelText: 'Year Obtained',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TouchableWidget(
                onTap: () {
                  _showCertificatePhotoDialog();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange.withOpacity(0.05),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.camera,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'Upload Certificate Photo',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 2),
                            TextWidget(
                              text: 'Add a photo of your certificate',
                              fontSize: 12,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                      const FaIcon(
                        FontAwesomeIcons.chevronRight,
                        color: Colors.orange,
                        size: 12,
                      ),
                    ],
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
                fontFamily: 'Medium',
                color: AppColors.onSecondary,
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty ||
                          yearController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .collection('certifications')
                            .add({
                          'name': nameController.text.trim(),
                          'year': yearController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Certification added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to add certification.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: isSaving ? 'Adding...' : 'Add',
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

  void _showCertificatePhotoDialog() {
    Navigator.pop(context); // Close the add certification dialog first
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.certificate,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextWidget(
                    text: 'Upload Certificate Photo',
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildCertificatePhotoOption('Take Photo', FontAwesomeIcons.camera,
                AppColors.primary.shade600),
            _buildCertificatePhotoOption('Choose from Gallery',
                FontAwesomeIcons.images, AppColors.secondary),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      // Reopen the add certification dialog
      _showAddCertificationDialog();
    });
  }

  Widget _buildCertificatePhotoOption(
      String title, IconData icon, Color color) {
    return TouchableWidget(
      onTap: () {
        Navigator.pop(context);
        // Handle certificate photo action
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

  // Sample data
  final List<Map<String, dynamic>> _residentialServices = [
    {
      'name': 'Regular House Cleaning',
      'description': 'Weekly or bi-weekly cleaning service',
      'price': '₱1,500',
      'duration': '2-3 hours',
      'icon': FontAwesomeIcons.house,
      'color': AppColors.primary,
    },
    {
      'name': 'Deep Cleaning',
      'description': 'Comprehensive cleaning service',
      'price': '₱3,000',
      'duration': '4-6 hours',
      'icon': FontAwesomeIcons.broom,
      'color': AppColors.primary.shade600,
    },
    {
      'name': 'Move-in/out Cleaning',
      'description': 'Complete cleaning for moving',
      'price': '₱4,500',
      'duration': '6-8 hours',
      'icon': FontAwesomeIcons.boxOpen,
      'color': AppColors.secondary,
    },
  ];

  final List<Map<String, dynamic>> _commercialServices = [
    {
      'name': 'Office Cleaning',
      'description': 'Regular office maintenance',
      'price': '₱2,500',
      'duration': '3-4 hours',
      'icon': FontAwesomeIcons.building,
      'color': AppColors.secondary,
    },
    {
      'name': 'Retail Space Cleaning',
      'description': 'Cleaning for retail establishments',
      'price': '₱3,500',
      'duration': '4-5 hours',
      'icon': FontAwesomeIcons.store,
      'color': AppColors.primary.shade700,
    },
  ];

  final List<Map<String, dynamic>> _specializedServices = [
    {
      'name': 'Carpet Cleaning',
      'description': 'Professional carpet cleaning',
      'price': '₱800',
      'duration': '1-2 hours',
      'icon': FontAwesomeIcons.rug,
      'color': AppColors.accent,
    },
    {
      'name': 'Window Cleaning',
      'description': 'Interior and exterior windows',
      'price': '₱600',
      'duration': '1 hour',
      'icon': FontAwesomeIcons.windowMaximize,
      'color': AppColors.primary.shade800,
    },
  ];

  // New provider-specific functions
  void _showEditProviderProfileDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to edit profile.')),
      );
      return;
    }

    String firstName = '';
    String lastName = '';
    String businessName = '';
    String phone = '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        firstName = (data['firstName'] ?? '').toString();
        lastName = (data['lastName'] ?? '').toString();
        businessName = (data['businessName'] ?? '').toString();
        phone = (data['phone'] ?? '').toString();
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.userPen,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextWidget(
                          text: 'Edit Provider Profile',
                          fontSize: 20,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                      ),
                      TouchableWidget(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  _buildEditField(
                    'First Name',
                    firstName,
                    FontAwesomeIcons.user,
                    (value) => firstName = value,
                  ),
                  const SizedBox(height: 16),
                  _buildEditField(
                    'Last Name',
                    lastName,
                    FontAwesomeIcons.user,
                    (value) => lastName = value,
                  ),
                  const SizedBox(height: 16),
                  _buildEditField(
                    'Business/Service Name',
                    businessName,
                    FontAwesomeIcons.building,
                    (value) => businessName = value,
                  ),
                  const SizedBox(height: 16),
                  _buildEditField(
                    'Phone Number',
                    phone,
                    FontAwesomeIcons.phone,
                    (value) => phone = value,
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TouchableWidget(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextWidget(
                                text: 'Cancel',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: AppColors.onSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TouchableWidget(
                          onTap: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('providers')
                                  .doc(uid)
                                  .set({
                                'firstName': firstName,
                                'lastName': lastName,
                                'businessName': businessName,
                                'phone': phone,
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Profile updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update profile.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextWidget(
                                text: 'Save Changes',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.white,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    String initialValue,
    IconData icon,
    ValueChanged<String> onChanged, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 14,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initialValue),
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showServiceManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Management'),
        content: const Text(
            'This feature allows you to add, edit, or remove your services. It will be available in the Services tab.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text(
            'Configure your notification preferences for booking updates, messages, and promotional offers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Settings'),
        content: const Text(
            'Manage your payment methods and view earnings history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
            'Control your privacy settings and security preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.rightFromBracket, size: 18),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/provider-login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout. Please try again.')),
      );
    }
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content:
            const Text('Access frequently asked questions and help articles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@hanapraket.com',
      query: 'subject=Provider Support Request',
    );

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+639123456789',
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Contact Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@hanapraket.com'),
              onTap: () async {
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+63 912 345 6789'),
              onTap: () async {
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProviderGuidelines() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provider Guidelines'),
        content: const Text(
            'Review the platform guidelines and best practices for providers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Service management functions
  void _showEditServiceDialog(
      QueryDocumentSnapshot<Map<String, dynamic>> serviceDoc) {
    final service = serviceDoc.data();
    final nameController = TextEditingController(text: service['name'] ?? '');
    final descController =
        TextEditingController(text: service['description'] ?? '');
    final priceController =
        TextEditingController(text: (service['price'] ?? 0).toString());
    final durationController =
        TextEditingController(text: service['duration'] ?? '');
    String selectedCategory = service['category'] ?? 'General Services';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  FontAwesomeIcons.edit,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextWidget(
                  text: 'Edit Service',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    hintText: 'e.g., House Cleaning',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the service',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    'Residential Cleaning',
                    'Commercial Cleaning',
                    'Specialized Services',
                    'General Services',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          hintText: '1500',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          hintText: '2-3 hours',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .collection('services')
                            .doc(serviceDoc.id)
                            .update({
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'category': selectedCategory,
                          'price': double.tryParse(priceController.text) ?? 0,
                          'duration': durationController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Service updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update service.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: isSaving ? 'Saving...' : 'Update Service',
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

  Future<void> _toggleServiceStatus(String serviceId, bool newStatus) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('services')
          .doc(serviceId)
          .update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'Service activated successfully!'
              : 'Service deactivated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update service status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteServiceDialog(String serviceId, String serviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Service'),
          ],
        ),
        content: Text(
            'Are you sure you want to delete "$serviceName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('providers')
                    .doc(uid)
                    .collection('services')
                    .doc(serviceId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Service deleted successfully!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete service.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit and delete functions for experience and certifications
  void _showEditExperienceDialog(String docId, String position, String company,
      String duration, String description) {
    final positionController = TextEditingController(text: position);
    final companyController = TextEditingController(text: company);
    final durationController = TextEditingController(text: duration);
    final descriptionController = TextEditingController(text: description);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: positionController,
                  decoration:
                      const InputDecoration(labelText: 'Position Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .collection('experience')
                            .doc(docId)
                            .update({
                          'position': positionController.text.trim(),
                          'company': companyController.text.trim(),
                          'duration': durationController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Experience updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update experience.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: Text(isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteExperienceDialog(String docId, String position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experience'),
        content: Text('Are you sure you want to delete "$position"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('providers')
                    .doc(uid)
                    .collection('experience')
                    .doc(docId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Experience deleted successfully!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete experience.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditCertificationDialog(String docId, String name, String year) {
    final nameController = TextEditingController(text: name);
    final yearController = TextEditingController(text: year);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Certification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Certification Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Year Obtained'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('providers')
                            .doc(uid)
                            .collection('certifications')
                            .doc(docId)
                            .update({
                          'name': nameController.text.trim(),
                          'year': yearController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Certification updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update certification.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: Text(isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCertificationDialog(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Certification'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('providers')
                    .doc(uid)
                    .collection('certifications')
                    .doc(docId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certification deleted successfully!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete certification.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
}
