import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';

import '../subscreens/faq_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _ensureDefaultPaymentMethod();
  }

  Future<void> _ensureDefaultPaymentMethod() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Ensure user profile exists with creation timestamp
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists || userDoc.data()?['createdAt'] == null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Ensure default payment method exists
      final paymentMethods = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('paymentMethods')
          .get();

      if (paymentMethods.docs.isEmpty) {
        // Create default cash payment method
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('paymentMethods')
            .add({
          'type': 'Cash',
          'accountNumber': 'Cash on delivery',
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently handle error
    }
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

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
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
          .child('$uid.jpg');

      await storageRef.putFile(_profileImage!);
      final downloadURL = await storageRef.getDownloadURL();

      // Update user document with profile picture URL
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Enhanced Header Section with modern design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextWidget(
                            text: 'Profile',
                            fontSize: 26,
                            fontFamily: 'Bold',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    // Profile Avatar and Info
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        children: [
                          // Enhanced Avatar
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: StreamBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          '_')
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
                                          radius: 50,
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: ClipOval(
                                            child: Image.file(
                                              _profileImage!,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      } else if (profilePicture != null &&
                                          profilePicture.isNotEmpty) {
                                        // Show image from Firebase Storage
                                        return CircleAvatar(
                                          radius: 50,
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: ClipOval(
                                            child: Image.network(
                                              profilePicture,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                // Fallback to default icon if image fails to load
                                                return const FaIcon(
                                                  FontAwesomeIcons.user,
                                                  color: AppColors.primary,
                                                  size: 40,
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    // Show default icon
                                    return CircleAvatar(
                                      radius: 50,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.1),
                                      child: const FaIcon(
                                        FontAwesomeIcons.user,
                                        color: AppColors.primary,
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
                                    _showImageSourceDialog();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.camera,
                                      color: AppColors.primary,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // User Info (from Firestore)
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid ??
                                    '_')
                                .snapshots(),
                            builder: (context, snapshot) {
                              final authUser =
                                  FirebaseAuth.instance.currentUser;
                              String displayName = authUser?.displayName ?? '';
                              String email = authUser?.email ?? '';
                              if (snapshot.hasData &&
                                  snapshot.data?.data() != null) {
                                final data = snapshot.data!.data()!;
                                final firstName =
                                    (data['firstName'] ?? '').toString().trim();
                                final lastName =
                                    (data['lastName'] ?? '').toString().trim();
                                final docEmail =
                                    (data['email'] ?? '').toString().trim();
                                final combined = [firstName, lastName]
                                    .where((e) => e.isNotEmpty)
                                    .join(' ')
                                    .trim();
                                if (combined.isNotEmpty) displayName = combined;
                                if (docEmail.isNotEmpty) email = docEmail;
                              }

                              if (displayName.isEmpty) {
                                displayName = 'User';
                              }
                              return Column(
                                children: [
                                  TextWidget(
                                    text: displayName,
                                    fontSize: 24,
                                    fontFamily: 'Bold',
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextWidget(
                                      text: 'Premium Customer',
                                      fontSize: 13,
                                      fontFamily: 'Medium',
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextWidget(
                                    text: email,
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          // Enhanced Stats
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid ??
                                    '_')
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              return StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('bookings')
                                    .where('userId',
                                        isEqualTo: FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '_')
                                    .snapshots(),
                                builder: (context, bookingsSnapshot) {
                                  // Show loading indicator while data is being fetched
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildEnhancedStat(
                                              '...',
                                              'Total\nBookings',
                                              FontAwesomeIcons.calendarCheck),
                                          _buildStatDivider(),
                                          _buildEnhancedStat(
                                              '...',
                                              'Average\nRating',
                                              FontAwesomeIcons.star),
                                          _buildStatDivider(),
                                          _buildEnhancedStat(
                                              '...',
                                              'Member\nSince',
                                              FontAwesomeIcons.userClock),
                                        ],
                                      ),
                                    );
                                  }

                                  // Calculate total bookings
                                  final totalBookings =
                                      bookingsSnapshot.data?.docs.length ?? 0;

                                  // Calculate average rating from completed bookings
                                  double averageRating = 0.0;
                                  if (bookingsSnapshot.hasData) {
                                    final completedBookings = bookingsSnapshot
                                        .data!.docs
                                        .where((doc) =>
                                            doc.data()['status'] ==
                                                'completed' &&
                                            doc.data()['rating'] != null)
                                        .toList();

                                    if (completedBookings.isNotEmpty) {
                                      final totalRating = completedBookings
                                          .map((doc) =>
                                              (doc.data()['rating'] as num)
                                                  .toDouble())
                                          .reduce((a, b) => a + b);
                                      averageRating = totalRating /
                                          completedBookings.length;
                                    }
                                  }

                                  // Get member since date
                                  String memberSince = 'New';
                                  final authUser =
                                      FirebaseAuth.instance.currentUser;
                                  if (authUser?.metadata.creationTime != null) {
                                    final creationYear =
                                        authUser!.metadata.creationTime!.year;
                                    memberSince = creationYear.toString();
                                  } else if (userSnapshot.hasData &&
                                      userSnapshot.data?.data() != null) {
                                    final userData = userSnapshot.data!.data()!;
                                    if (userData['createdAt'] != null) {
                                      final createdAt =
                                          userData['createdAt'] as Timestamp;
                                      memberSince =
                                          createdAt.toDate().year.toString();
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildEnhancedStat(
                                            totalBookings.toString(),
                                            'Total\nBookings',
                                            FontAwesomeIcons.calendarCheck),
                                        _buildStatDivider(),
                                        _buildEnhancedStat(
                                            averageRating > 0
                                                ? averageRating
                                                    .toStringAsFixed(1)
                                                : 'N/A',
                                            'Average\nRating',
                                            FontAwesomeIcons.star),
                                        _buildStatDivider(),
                                        _buildEnhancedStat(
                                            memberSince,
                                            'Member\nSince',
                                            FontAwesomeIcons.userClock),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section (from Firestore)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final authUser = FirebaseAuth.instance.currentUser;
                      final data = snapshot.data?.data() ?? {};
                      final firstName =
                          (data['firstName'] ?? '').toString().trim();
                      final lastName =
                          (data['lastName'] ?? '').toString().trim();
                      final email =
                          ((data['email'] ?? authUser?.email) ?? '').toString();
                      final phone = (data['phone'] ?? '').toString();
                      final address = (data['address'] ?? '—').toString();
                      final fullName = [firstName, lastName]
                          .where((e) => e.isNotEmpty)
                          .join(' ')
                          .trim();

                      return _buildSectionCard(
                        'Personal Information',
                        FontAwesomeIcons.user,
                        AppColors.primary,
                        [
                          _buildInfoTile(
                            FontAwesomeIcons.user,
                            'Full Name',
                            fullName.isNotEmpty
                                ? fullName
                                : (authUser?.displayName ?? '—'),
                          ),
                          _buildInfoTile(
                            FontAwesomeIcons.envelope,
                            'Email',
                            email.isNotEmpty ? email : '—',
                          ),
                          _buildInfoTile(
                            FontAwesomeIcons.phone,
                            'Phone Number',
                            phone.isNotEmpty ? phone : '—',
                          ),
                          _buildInfoTile(
                            FontAwesomeIcons.locationDot,
                            'Address',
                            address.isNotEmpty ? address : '—',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Saved Addresses Section
                  _buildSectionCard(
                    'Saved Addresses',
                    FontAwesomeIcons.mapMarkerAlt,
                    Colors.orange,
                    [
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
                            .collection('addresses')
                            .orderBy('isDefault', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: TextWidget(
                                text: 'Failed to load addresses',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: Colors.red,
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          List<Widget> addressWidgets = [];

                          for (final doc in docs) {
                            final data = doc.data();
                            final label =
                                (data['label'] ?? 'Address').toString();
                            final address = (data['address'] ?? '').toString();
                            final isDefault =
                                (data['isDefault'] ?? false) == true;
                            final type = (data['type'] ?? 'Home').toString();

                            IconData icon;
                            switch (type) {
                              case 'Work':
                                icon = FontAwesomeIcons.building;
                                break;
                              case 'Other':
                                icon = FontAwesomeIcons.heart;
                                break;
                              default:
                                icon = FontAwesomeIcons.home;
                            }

                            addressWidgets.add(
                              _buildAddressTile(
                                label,
                                address,
                                icon,
                                isDefault,
                                () => _showEditAddressDialog(
                                    doc.id, label, address, type),
                                () => _showDeleteAddressDialog(doc.id, label),
                              ),
                            );
                          }

                          if (docs.isEmpty) {
                            addressWidgets.add(
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: TextWidget(
                                  text: 'No saved addresses yet.',
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.7),
                                  align: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          addressWidgets.add(_buildAddNewAddressTile());

                          return Column(children: addressWidgets);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Account Settings Section
                  _buildSectionCard(
                    'Account Settings',
                    FontAwesomeIcons.gear,
                    Colors.blue,
                    [
                      _buildMenuTile(
                        FontAwesomeIcons.userPen,
                        'Edit Profile',
                        'Update your personal information',
                        () => _showEditProfileDialog(),
                      ),
                      _buildMenuTile(
                        FontAwesomeIcons.bell,
                        'Notifications',
                        'Manage notification preferences',
                        () => _showNotificationSettings(),
                      ),
                      _buildMenuTile(
                        FontAwesomeIcons.creditCard,
                        'Payment Methods',
                        'Manage payment options',
                        () => _showPaymentMethods(),
                      ),
                      _buildMenuTile(
                        FontAwesomeIcons.shield,
                        'Privacy & Security',
                        'Control privacy settings',
                        () => _showPrivacySettings(),
                      ),
                      _buildMenuTile(
                        FontAwesomeIcons.rightFromBracket,
                        'Logout',
                        'Sign out of this device',
                        () => _showLogoutDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Support Section
                  _buildSectionCard(
                    'Support',
                    FontAwesomeIcons.headset,
                    Colors.green,
                    [
                      _buildMenuTile(
                        FontAwesomeIcons.circleQuestion,
                        'Help Center (FAQ)',
                        'Browse frequently asked questions',
                        () => Get.to(() => const FAQScreen()),
                      ),
                      _buildMenuTile(
                        FontAwesomeIcons.headset,
                        'Contact Support',
                        'Call or email our support team',
                        () => _contactSupport(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentMethodDialog(
    String docId,
    String currentType,
    String currentAccount,
  ) {
    String selectedType = currentType.isNotEmpty ? currentType : 'Cash';
    List<String> paymentTypes = ['Cash'];
    final accountController = TextEditingController(text: currentAccount);
    bool isSaving = false;
    String? inputError;

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
                  FontAwesomeIcons.pen,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Edit Payment Method',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Payment Type',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                items: paymentTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: TextWidget(
                      text: type,
                      fontSize: 14,
                      fontFamily: 'Medium',
                      color: AppColors.onSecondary,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedType = value!);
                },
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Account Details',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accountController,
                decoration: InputDecoration(
                  hintText: 'Enter account number or card details',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  errorText: inputError,
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
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      String account = accountController.text.trim();
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Please sign in to edit a payment method.',
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
                      if (account.isEmpty) {
                        // For cash, account details are optional
                        // Set a default message
                        account = 'Cash on delivery';
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('paymentMethods')
                            .doc(docId)
                            .update({
                          'type': selectedType,
                          'accountNumber': account,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TextWidget(
                                text: 'Payment method updated successfully!',
                                fontSize: 14,
                                fontFamily: 'Medium',
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.blue,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Failed to update payment method.',
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
              child: TextWidget(
                text: 'Save Changes',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefaultPaymentMethod(String targetDocId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please sign in to set a default payment method.',
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

    try {
      final colRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('paymentMethods');
      final snapshot = await colRef.get();

      final batch = FirebaseFirestore.instance.batch();
      for (final d in snapshot.docs) {
        batch.update(d.reference, {
          'isDefault': d.id == targetDocId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Default payment method updated.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Failed to set default payment method.',
            fontSize: 14,
            fontFamily: 'Medium',
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Removed stray duplicated UI block between _setDefaultPaymentMethod and _showLogoutDialog.

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            FaIcon(FontAwesomeIcons.rightFromBracket, size: 18),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
        ),
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
      Get.offAllNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout. Please try again.')),
      );
    }
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

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color iconColor,
    List<Widget> children,
  ) {
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
              color: iconColor.withOpacity(0.1),
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
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(
                    icon,
                    color: iconColor,
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
          ),
          // Section Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
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
                  text: label,
                  fontSize: 13,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary.withOpacity(0.7),
                ),
                const SizedBox(height: 2),
                TextWidget(
                  text: value,
                  fontSize: 15,
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

  Widget _buildAddressTile(
    String label,
    String address,
    IconData icon,
    bool isDefault,
    VoidCallback onEdit,
    VoidCallback onDelete,
  ) {
    return TouchableWidget(
      onTap: onEdit,
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
                  Row(
                    children: [
                      TextWidget(
                        text: label,
                        fontSize: 15,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextWidget(
                            text: 'Default',
                            fontSize: 10,
                            fontFamily: 'Bold',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: address,
                    fontSize: 13,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TouchableWidget(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.pen,
                      color: Colors.blue,
                      size: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TouchableWidget(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.trash,
                      color: Colors.red,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddressTile() {
    return TouchableWidget(
      onTap: () {
        _showAddAddressDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: FaIcon(
                FontAwesomeIcons.plus,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextWidget(
                text: 'Add New Address',
                fontSize: 15,
                fontFamily: 'Bold',
                color: AppColors.primary,
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

  Widget _buildAddressTypeChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return TouchableWidget(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: isSelected ? Colors.white : AppColors.onSecondary,
              size: 14,
            ),
            const SizedBox(width: 6),
            TextWidget(
              text: label,
              fontSize: 13,
              fontFamily: 'Medium',
              color: isSelected ? Colors.white : AppColors.onSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    String addressDetails = '';
    String selectedAddressType = 'Home';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
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
                        child: FaIcon(
                          FontAwesomeIcons.mapMarkerAlt,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextWidget(
                          text: 'Add New Address',
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

                  // Address Type Selection
                  TextWidget(
                    text: 'Address Type',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAddressTypeChip(
                        'Home',
                        FontAwesomeIcons.home,
                        selectedAddressType == 'Home',
                        () {
                          setDialogState(() {
                            selectedAddressType = 'Home';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildAddressTypeChip(
                        'Work',
                        FontAwesomeIcons.building,
                        selectedAddressType == 'Work',
                        () {
                          setDialogState(() {
                            selectedAddressType = 'Work';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildAddressTypeChip(
                        'Other',
                        FontAwesomeIcons.heart,
                        selectedAddressType == 'Other',
                        () {
                          setDialogState(() {
                            selectedAddressType = 'Other';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Map Placeholder with Search
                  TextWidget(
                    text: 'Location',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        // Map Placeholder
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.green.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.map,
                                  color: AppColors.primary.withOpacity(0.5),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                TextWidget(
                                  text: 'Interactive Map',
                                  fontSize: 14,
                                  fontFamily: 'Medium',
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                                TextWidget(
                                  text: 'Tap to select location',
                                  fontSize: 12,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Search Bar Overlay
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search location...',
                                hintStyle: TextStyle(
                                  color: AppColors.onSecondary.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    // Get current location
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: TextWidget(
                                          text: 'Getting current location...',
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                          color: Colors.white,
                                        ),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Location Marker
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Details
                  TextWidget(
                    text: 'Complete Address',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Enter complete address details\n(House/Unit number, Street, Barangay, City)',
                        hintStyle: TextStyle(
                          color: AppColors.onSecondary.withOpacity(0.5),
                          fontSize: 14,
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
                      onChanged: (value) => addressDetails = value,
                    ),
                  ),
                  const SizedBox(height: 20),

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
                            if (addressDetails.trim().isNotEmpty) {
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('addresses')
                                      .add({
                                    'label': selectedAddressType == 'Other'
                                        ? 'Custom Address'
                                        : selectedAddressType,
                                    'address': addressDetails.trim(),
                                    'type': selectedAddressType,
                                    'isDefault': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: TextWidget(
                                          text: 'Address added successfully!',
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                          color: Colors.white,
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: TextWidget(
                                          text:
                                              'Failed to add address. Please try again.',
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                          color: Colors.white,
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: TextWidget(
                                        text:
                                            'Please sign in to add an address.',
                                        fontSize: 14,
                                        fontFamily: 'Medium',
                                        color: Colors.white,
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Please enter address details.',
                                    fontSize: 14,
                                    fontFamily: 'Medium',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
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
                                text: 'Save Address',
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

  void _showEditAddressDialog(
      String docId, String label, String address, String type) {
    String addressDetails = address;
    String selectedAddressType = type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.pen,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextWidget(
                          text: 'Edit $label Address',
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

                  // Address Type Selection
                  TextWidget(
                    text: 'Address Type',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAddressTypeChip(
                        'Home',
                        FontAwesomeIcons.home,
                        selectedAddressType == 'Home',
                        () {
                          setDialogState(() {
                            selectedAddressType = 'Home';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildAddressTypeChip(
                        'Work',
                        FontAwesomeIcons.building,
                        selectedAddressType == 'Work',
                        () {
                          setDialogState(() {
                            selectedAddressType = 'Work';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildAddressTypeChip(
                        'Other',
                        FontAwesomeIcons.heart,
                        selectedAddressType == 'Other',
                        () {
                          setDialogState(() {
                            selectedAddressType = 'Other';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Map Placeholder with Search
                  TextWidget(
                    text: 'Location',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        // Map Placeholder
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.green.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.map,
                                  color: AppColors.primary.withOpacity(0.5),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                TextWidget(
                                  text: 'Interactive Map',
                                  fontSize: 14,
                                  fontFamily: 'Medium',
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                                TextWidget(
                                  text: 'Current location marked',
                                  fontSize: 12,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Search Bar Overlay
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search new location...',
                                hintStyle: TextStyle(
                                  color: AppColors.onSecondary.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: TextWidget(
                                          text: 'Getting current location...',
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                          color: Colors.white,
                                        ),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Location Marker
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_location,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Details
                  TextWidget(
                    text: 'Complete Address',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: TextField(
                      controller: TextEditingController(text: addressDetails),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Enter complete address details\n(House/Unit number, Street, Barangay, City)',
                        hintStyle: TextStyle(
                          color: AppColors.onSecondary.withOpacity(0.5),
                          fontSize: 14,
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
                      onChanged: (value) => addressDetails = value,
                    ),
                  ),
                  const SizedBox(height: 20),

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
                            if (addressDetails.trim().isNotEmpty) {
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('addresses')
                                      .doc(docId)
                                      .update({
                                    'label': selectedAddressType == 'Other'
                                        ? 'Custom Address'
                                        : selectedAddressType,
                                    'address': addressDetails.trim(),
                                    'type': selectedAddressType,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: TextWidget(
                                          text: 'Address updated successfully!',
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                          color: Colors.white,
                                        ),
                                        backgroundColor: Colors.blue,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: TextWidget(
                                          text:
                                              'Failed to update address. Please try again.',
                                          fontSize: 14,
                                          fontFamily: 'Medium',
                                          color: Colors.white,
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: TextWidget(
                                        text:
                                            'Please sign in to edit an address.',
                                        fontSize: 14,
                                        fontFamily: 'Medium',
                                        color: Colors.white,
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Please enter address details.',
                                    fontSize: 14,
                                    fontFamily: 'Medium',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.blue.withOpacity(0.8),
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

  void _showDeleteAddressDialog(String docId, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: 'Delete Address',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.red,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              text: 'Are you sure you want to delete "$label" address?',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
              align: TextAlign.center,
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
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('addresses')
                      .doc(docId)
                      .delete();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text: 'Address deleted successfully!',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Failed to delete address.',
                        fontSize: 14,
                        fontFamily: 'Medium',
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: TextWidget(
              text: 'Delete',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to edit profile.')),
      );
      return;
    }

    String fullName = '';
    String email = FirebaseAuth.instance.currentUser?.email ?? '';
    String phone = '';
    String address = '';

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final firstName = (data['firstName'] ?? '').toString();
        final lastName = (data['lastName'] ?? '').toString();
        fullName = [firstName, lastName]
            .where((e) => e.trim().isNotEmpty)
            .join(' ')
            .trim();
        email = (data['email'] ?? email).toString();
        phone = (data['phone'] ?? '').toString();
        address = (data['address'] ?? '').toString();
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
                        child: FaIcon(
                          FontAwesomeIcons.userPen,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextWidget(
                          text: 'Edit Profile',
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

                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid ??
                                    '_')
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
                                    radius: 50,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    child: ClipOval(
                                      child: Image.file(
                                        _profileImage!,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                } else if (profilePicture != null &&
                                    profilePicture.isNotEmpty) {
                                  // Show image from Firebase Storage
                                  return CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    child: ClipOval(
                                      child: Image.network(
                                        profilePicture,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Fallback to default icon if image fails to load
                                          return const FaIcon(
                                            FontAwesomeIcons.user,
                                            color: AppColors.primary,
                                            size: 40,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }

                              // Show default icon
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: const FaIcon(
                                  FontAwesomeIcons.user,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Fields
                  _buildEditField(
                    'Full Name',
                    fullName,
                    FontAwesomeIcons.user,
                    (value) => fullName = value,
                  ),
                  const SizedBox(height: 16),
                  _buildEditField(
                    'Email Address',
                    email,
                    FontAwesomeIcons.envelope,
                    (value) => email = value,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildEditField(
                    'Phone Number',
                    phone,
                    FontAwesomeIcons.phone,
                    (value) => phone = value,
                  ),
                  const SizedBox(height: 16),
                  _buildEditField(
                    'Address',
                    address,
                    FontAwesomeIcons.locationDot,
                    (value) => address = value,
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
                              final parts = fullName
                                  .trim()
                                  .split(RegExp(r"\s+"))
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                              final firstName =
                                  parts.isNotEmpty ? parts.first : '';
                              final lastName = parts.length > 1
                                  ? parts.sublist(1).join(' ')
                                  : '';

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .set({
                                'firstName': firstName,
                                'lastName': lastName,
                                'phone': phone,
                                'address': address,
                                'email': email,
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Profile updated successfully!',
                                    fontSize: 14,
                                    fontFamily: 'Medium',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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

  void _showNotificationSettings() {
    bool pushNotifications = true;
    bool emailNotifications = false;
    bool smsNotifications = true;
    bool bookingUpdates = true;
    bool promotionalOffers = false;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.bell,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextWidget(
                        text: 'Notification Settings',
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNotificationSwitch(
                          FontAwesomeIcons.bell,
                          'Push Notifications',
                          'Receive notifications on your device',
                          pushNotifications,
                          (value) =>
                              setDialogState(() => pushNotifications = value),
                        ),
                        _buildNotificationSwitch(
                          FontAwesomeIcons.envelope,
                          'Email Notifications',
                          'Receive notifications via email',
                          emailNotifications,
                          (value) =>
                              setDialogState(() => emailNotifications = value),
                        ),
                        _buildNotificationSwitch(
                          FontAwesomeIcons.commentSms,
                          'SMS Notifications',
                          'Receive notifications via SMS',
                          smsNotifications,
                          (value) =>
                              setDialogState(() => smsNotifications = value),
                        ),
                        _buildNotificationSwitch(
                          FontAwesomeIcons.calendar,
                          'Booking Updates',
                          'Get notified about booking changes',
                          bookingUpdates,
                          (value) =>
                              setDialogState(() => bookingUpdates = value),
                        ),
                        _buildNotificationSwitch(
                          FontAwesomeIcons.tags,
                          'Promotional Offers',
                          'Receive deals and special offers',
                          promotionalOffers,
                          (value) =>
                              setDialogState(() => promotionalOffers = value),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                TouchableWidget(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text: 'Notification settings saved!',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange,
                          Colors.orange.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: TextWidget(
                        text: 'Save Settings',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
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
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please sign in to manage payment methods.',
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.creditCard,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: 'Payment Methods',
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
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('paymentMethods')
                      .orderBy('isDefault', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: TextWidget(
                          text: 'Failed to load payment methods',
                          fontSize: 14,
                          fontFamily: 'Medium',
                          color: Colors.red,
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: TextWidget(
                          text: 'No payment methods yet.',
                          fontSize: 14,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final type = (data['type'] ?? '').toString();
                        final account =
                            (data['accountNumber'] ?? '').toString();
                        final isDefault = (data['isDefault'] ?? false) == true;
                        final icon = _paymentTypeIcon(type);
                        final color = _paymentTypeColor(type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDefault
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isDefault ? 2 : 1,
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
                                        TextWidget(
                                          text: type.isEmpty ? 'Payment' : type,
                                          fontSize: 16,
                                          fontFamily: 'Bold',
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: TextWidget(
                                          text: 'Default',
                                          fontSize: 10,
                                          fontFamily: 'Bold',
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],

                                    // TextWidget(
                                    //   text: _maskAccount(account),
                                    //   fontSize: 14,
                                    //   fontFamily: 'Regular',
                                    //   color: AppColors.onSecondary
                                    //       .withOpacity(0.7),
                                    // ),
                                  ],
                                ),
                              ),
                              // Row(
                              //   children: [
                              //     TouchableWidget(
                              //       onTap: () {
                              //         _showEditPaymentMethodDialog(
                              //           doc.id,
                              //           type,
                              //           account,
                              //         );
                              //       },
                              //       child: Container(
                              //         padding: const EdgeInsets.all(8),
                              //         decoration: BoxDecoration(
                              //           color: Colors.blue.withOpacity(0.1),
                              //           borderRadius: BorderRadius.circular(8),
                              //         ),
                              //         child: const FaIcon(
                              //           FontAwesomeIcons.pen,
                              //           color: Colors.blue,
                              //           size: 14,
                              //         ),
                              //       ),
                              //     ),
                              //     const SizedBox(width: 8),
                              //     // Set as Default action
                              //     if (!isDefault) ...[
                              //       TouchableWidget(
                              //         onTap: () async {
                              //           await _setDefaultPaymentMethod(doc.id);
                              //         },
                              //         child: Container(
                              //           padding: const EdgeInsets.all(8),
                              //           decoration: BoxDecoration(
                              //             color: AppColors.primary
                              //                 .withOpacity(0.1),
                              //             borderRadius:
                              //                 BorderRadius.circular(8),
                              //           ),
                              //           child: const FaIcon(
                              //             FontAwesomeIcons.star,
                              //             color: AppColors.primary,
                              //             size: 14,
                              //           ),
                              //         ),
                              //       ),
                              //       const SizedBox(width: 8),
                              //     ],
                              //     if (!isDefault)
                              //       TouchableWidget(
                              //         onTap: () {
                              //           _showDeletePaymentDialog(doc.id, type);
                              //         },
                              //         child: Container(
                              //           padding: const EdgeInsets.all(8),
                              //           decoration: BoxDecoration(
                              //             color: Colors.red.withOpacity(0.1),
                              //             borderRadius:
                              //                 BorderRadius.circular(8),
                              //           ),
                              //           child: const FaIcon(
                              //             FontAwesomeIcons.trash,
                              //             color: Colors.red,
                              //             size: 14,
                              //           ),
                              //         ),
                              //       ),
                              //   ],
                              // ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // // Add New Payment Method Button
              // TouchableWidget(
              //   onTap: () {
              //     _showAddPaymentMethodDialog();
              //   },
              //   child: Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.symmetric(vertical: 14),
              //     decoration: BoxDecoration(
              //       gradient: LinearGradient(
              //         colors: [
              //           Colors.green,
              //           Colors.green.withOpacity(0.8),
              //         ],
              //       ),
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         const FaIcon(
              //           FontAwesomeIcons.plus,
              //           color: Colors.white,
              //           size: 16,
              //         ),
              //         const SizedBox(width: 8),
              //         TextWidget(
              //           text: 'Add New Payment Method',
              //           fontSize: 16,
              //           fontFamily: 'Bold',
              //           color: Colors.white,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    String selectedType = 'Cash';
    List<String> paymentTypes = ['Cash'];
    final accountController = TextEditingController();
    bool isSaving = false;
    String? inputError;

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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.plus,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Add Payment Method',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Payment Type',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                items: paymentTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: TextWidget(
                      text: type,
                      fontSize: 14,
                      fontFamily: 'Medium',
                      color: AppColors.onSecondary,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedType = value!);
                },
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Account Details',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accountController,
                decoration: InputDecoration(
                  hintText: 'Enter account number or card details',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  errorText: inputError,
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
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      String account = accountController.text.trim();
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Please sign in to add a payment method.',
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
                      if (account.isEmpty) {
                        // For cash, account details are optional
                        // Set a default message
                        account = 'Cash on delivery';
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('paymentMethods')
                            .add({
                          'type': selectedType,
                          'accountNumber': account,
                          'isDefault': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TextWidget(
                                text: 'Payment method added successfully!',
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
                              text: 'Failed to add payment method.',
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
              child: TextWidget(
                text: 'Add Method',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePaymentDialog(String docId, String paymentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: 'Remove Payment Method',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.red,
        ),
        content: TextWidget(
          text:
              'Are you sure you want to remove this $paymentType payment method?',
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary,
          align: TextAlign.center,
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
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Please sign in to remove a payment method.',
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
              // Prevent deleting the default payment method
              try {
                final docRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('paymentMethods')
                    .doc(docId);
                final current = await docRef.get();
                final isDefault =
                    (current.data()?['isDefault'] ?? false) == true;
                if (isDefault) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text:
                            'Cannot remove the default payment method. Set another as default first.',
                        fontSize: 14,
                        fontFamily: 'Medium',
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              } catch (_) {}
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('paymentMethods')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Payment method removed successfully!',
                        fontSize: 14,
                        fontFamily: 'Medium',
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Failed to remove payment method.',
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
            child: TextWidget(
              text: 'Remove',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacySettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please sign in to manage privacy settings.',
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

    bool profileVisibility = true;
    bool dataSharing = false;
    bool locationTracking = true;
    bool analyticsOptOut = false;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      final privacy = (data != null && data['privacy'] is Map)
          ? Map<String, dynamic>.from(data['privacy'])
          : <String, dynamic>{};
      profileVisibility =
          (privacy['profileVisibility'] as bool?) ?? profileVisibility;
      dataSharing = (privacy['dataSharing'] as bool?) ?? dataSharing;
      locationTracking =
          (privacy['locationTracking'] as bool?) ?? locationTracking;
      analyticsOptOut =
          (privacy['analyticsOptOut'] as bool?) ?? analyticsOptOut;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.shield,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextWidget(
                        text: 'Privacy & Security',
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildPrivacySwitch(
                          FontAwesomeIcons.eye,
                          'Profile Visibility',
                          'Allow others to see your profile information',
                          profileVisibility,
                          (value) =>
                              setDialogState(() => profileVisibility = value),
                        ),
                        _buildPrivacySwitch(
                          FontAwesomeIcons.shareNodes,
                          'Data Sharing',
                          'Share anonymized data for service improvement',
                          dataSharing,
                          (value) => setDialogState(() => dataSharing = value),
                        ),
                        _buildPrivacySwitch(
                          FontAwesomeIcons.locationDot,
                          'Location Tracking',
                          'Allow location tracking for better service matching',
                          locationTracking,
                          (value) =>
                              setDialogState(() => locationTracking = value),
                        ),
                        _buildPrivacySwitch(
                          FontAwesomeIcons.chartLine,
                          'Analytics Opt-out',
                          'Opt out of analytics and usage tracking',
                          analyticsOptOut,
                          (value) =>
                              setDialogState(() => analyticsOptOut = value),
                        ),

                        const SizedBox(height: 20),

                        // Security Actions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Security Actions',
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              _buildSecurityAction(
                                FontAwesomeIcons.key,
                                'Change Password',
                                'Update your account password',
                                () => _showChangePasswordDialog(),
                              ),
                              _buildSecurityAction(
                                FontAwesomeIcons.rightFromBracket,
                                'Logout All Devices',
                                'Sign out from all logged-in devices',
                                () => _showLogoutAllDialog(),
                              ),
                              _buildSecurityAction(
                                FontAwesomeIcons.trash,
                                'Delete Account',
                                'Permanently delete your account',
                                () => _showDeleteAccountDialog(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                TouchableWidget(
                  onTap: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'privacy': {
                          'profileVisibility': profileVisibility,
                          'dataSharing': dataSharing,
                          'locationTracking': locationTracking,
                          'analyticsOptOut': analyticsOptOut,
                        }
                      }, SetOptions(merge: true));
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TextWidget(
                              text: 'Privacy settings saved!',
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: TextWidget(
                            text: 'Failed to save privacy settings.',
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.purple.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: TextWidget(
                        text: 'Save Settings',
                        fontSize: 16,
                        fontFamily: 'Bold',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySwitch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
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
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: Colors.red,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: title,
                    fontSize: 14,
                    fontFamily: 'Bold',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 2),
                  TextWidget(
                    text: subtitle,
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              color: Colors.red.withOpacity(0.5),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: 'Change Password',
          fontSize: 18,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TextWidget(
                    text: 'Password changed successfully!',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: TextWidget(
              text: 'Change Password',
              fontSize: 14,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: 'Logout All Devices',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.orange,
        ),
        content: TextWidget(
          text:
              'This will sign you out from all devices. You will need to log in again on each device.',
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary,
          align: TextAlign.center,
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TextWidget(
                    text: 'Logged out from all devices!',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: TextWidget(
              text: 'Logout All',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: 'Delete Account',
          fontSize: 18,
          fontFamily: 'Bold',
          color: Colors.red,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              text:
                  'Are you sure you want to permanently delete your account? This action cannot be undone.',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
              align: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TextWidget(
                    text:
                        'Account deletion initiated. You will receive a confirmation email.',
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: TextWidget(
              text: 'Delete Account',
              fontSize: 14,
              fontFamily: 'Bold',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport() async {
    const phoneNumber =
        'tel:+639123456789'; // Replace with your actual support number

    try {
      final Uri phoneUri = Uri.parse(phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Fallback: Show dialog with support options
        _showSupportDialog();
      }
    } catch (e) {
      // If phone call fails, show support dialog
      _showSupportDialog();
    }
  }

  void _showSupportDialog() {
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
                FontAwesomeIcons.headset,
                color: Colors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'Contact Support',
              fontSize: 18,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: 'Get in touch with our support team:',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              FontAwesomeIcons.phone,
              'Call Us',
              '+63 912 345 6789',
              Colors.green,
              () async {
                Navigator.pop(context);
                const phoneNumber = 'tel:+639123456789';
                final Uri phoneUri = Uri.parse(phoneNumber);
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              FontAwesomeIcons.envelope,
              'Email Us',
              'support@hanapraket.com',
              Colors.blue,
              () async {
                Navigator.pop(context);
                const email =
                    'mailto:support@hanapraket.com?subject=Support Request';
                final Uri emailUri = Uri.parse(email);
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              FontAwesomeIcons.facebook,
              'Facebook',
              'facebook.com/hanapraket',
              Colors.indigo,
              () async {
                Navigator.pop(context);
                const facebookUrl = 'https://facebook.com/hanapraket';
                final Uri facebookUri = Uri.parse(facebookUrl);
                if (await canLaunchUrl(facebookUri)) {
                  await launchUrl(facebookUri);
                }
              },
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
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
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
                    fontSize: 14,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 2),
                  TextWidget(
                    text: subtitle,
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.externalLink,
              color: color.withOpacity(0.7),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  // Helpers for payment method rendering
  IconData _paymentTypeIcon(String type) {
    switch (type) {
      case 'Cash':
        return FontAwesomeIcons.moneyBill;
      default:
        return FontAwesomeIcons.moneyBill;
    }
  }

  Color _paymentTypeColor(String type) {
    switch (type) {
      case 'Cash':
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  String _maskAccount(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '****';
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '**** **** **** $last4';
  }
}
