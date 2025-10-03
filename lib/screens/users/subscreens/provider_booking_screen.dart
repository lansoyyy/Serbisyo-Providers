import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import 'viewprovider_profile_screen.dart';

class ProviderBookingScreen extends StatefulWidget {
  final String providerName;
  final double rating;
  final int reviews;
  final String experience;
  final bool verified;
  final String description;
  final bool isOnline;
  final String? providerId; // Add provider ID parameter
  final String? initialSelectedService; // Add this new parameter

  const ProviderBookingScreen({
    Key? key,
    required this.providerName,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.verified,
    required this.description,
    this.isOnline = false,
    this.providerId, // Add this new parameter
    this.initialSelectedService, // Add this new parameter
  }) : super(key: key);

  @override
  State<ProviderBookingScreen> createState() => _ProviderBookingScreenState();
}

class _ProviderBookingScreenState extends State<ProviderBookingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedService = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedLocation = 'Home Service';
  String _contactNumber = '';
  String _address = '';
  String _paymentMethod = 'Cash';
  String _selectedSavedLocation = '';
  String _notes = '';

  // Controllers for text fields
  late TextEditingController _contactNumberController;
  late TextEditingController _addressController;

  // Replace hardcoded data with dynamic data
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _serviceLocations = [];
  List<String> _paymentMethods = [];
  List<Map<String, String>> _savedLocations = [];

  // Loading states
  bool _isLoadingServices = true;
  bool _isLoadingLocations = true;
  bool _isLoadingPaymentMethods = true;
  bool _isLoadingSavedLocations = true;

  @override
  void initState() {
    super.initState();

    // Initialize text controllers
    _contactNumberController = TextEditingController();
    _addressController = TextEditingController();

    _loadProviderData();

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
  }

  // Load all necessary data from Firebase
  void _loadProviderData() async {
    try {
      await _loadProviderServices();
      await _loadServiceLocations();
      await _loadPaymentMethods();
      await _loadSavedLocations();
      await _loadUserContactInfo(); // Load user's contact information

      // The service selection is now handled in _loadProviderServices method

      if (_paymentMethods.isNotEmpty && _paymentMethod.isEmpty) {
        setState(() {
          _paymentMethod = _paymentMethods[0];
        });
      }
    } catch (e) {
      print('Error loading provider data: $e');
      // Fallback to default data in case of error
      _loadDefaultData();
    }
  }

  // Load services offered by this specific provider
  Future<void> _loadProviderServices() async {
    try {
      // Get the provider document to find their ID
      QuerySnapshot providersSnapshot;

      // Try multiple approaches to find the provider
      print('Searching for provider with name: ${widget.providerName}');

      // Approach 1: Try to match by fullName field (the standard way providers are stored)
      providersSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .where('fullName', isEqualTo: widget.providerName)
          .where('applicationStatus', isEqualTo: 'approved')
          .get();
      print('Approach 1 - Found ${providersSnapshot.docs.length} providers');

      // Approach 2: Try matching by businessName
      if (providersSnapshot.docs.isEmpty) {
        providersSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .where('businessName', isEqualTo: widget.providerName)
            .where('applicationStatus', isEqualTo: 'approved')
            .get();
        print('Approach 2 - Found ${providersSnapshot.docs.length} providers');
      }

      // Approach 3: Try to match by firstName field (in case stored differently)
      if (providersSnapshot.docs.isEmpty) {
        providersSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .where('firstName', isEqualTo: widget.providerName)
            .where('applicationStatus', isEqualTo: 'approved')
            .get();
        print('Approach 3 - Found ${providersSnapshot.docs.length} providers');
      }

      if (providersSnapshot.docs.isNotEmpty) {
        // If multiple providers with same name, use the first one
        // In a real app, you'd want to pass provider ID to avoid this issue
        final providerDoc = providersSnapshot.docs.first;
        final providerId = providerDoc.id;
        print('Found provider with ID: $providerId');

        // Get services for this provider
        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .collection('services')
            .get();

        print('Found ${servicesSnapshot.docs.length} services for provider');

        final servicesList = <Map<String, dynamic>>[];
        for (var doc in servicesSnapshot.docs) {
          final serviceData = doc.data() as Map<String, dynamic>;
          servicesList.add({
            'id': doc.id, // Add document ID for reference
            'name': serviceData['name'] as String? ?? 'Service',
            'description': serviceData['description'] as String? ?? '',
            'price': serviceData['price'] as num? ?? 0,
            'duration':
                serviceData['duration'] as String? ?? 'Duration not specified',
          });
        }

        setState(() {
          _services = servicesList;
          _isLoadingServices = false;

          // Set default selection if none selected
          if (servicesList.isNotEmpty && _selectedService.isEmpty) {
            // Use the initial selected service if provided and it exists in the services list
            bool foundInitialService = false;
            if (widget.initialSelectedService != null) {
              for (var service in servicesList) {
                if (service['name'] == widget.initialSelectedService) {
                  _selectedService = widget.initialSelectedService!;
                  foundInitialService = true;
                  break;
                }
              }
            }

            // If no initial service was provided or it wasn't found, use the first service
            if (!foundInitialService) {
              _selectedService = servicesList[0]['name'] as String;
            }
          }
        });
      } else {
        print('No provider found with name: ${widget.providerName}');
        setState(() {
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      print('Error loading provider services: $e');
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  // Load service locations (this could be customized per provider)
  Future<void> _loadServiceLocations() async {
    try {
      // Fetch service locations from Firebase
      final locationsSnapshot =
          await FirebaseFirestore.instance.collection('serviceLocations').get();

      final locationsList = <Map<String, dynamic>>[];

      if (locationsSnapshot.docs.isNotEmpty) {
        // Use data from Firebase
        for (var doc in locationsSnapshot.docs) {
          final locationData = doc.data() as Map<String, dynamic>;
          IconData icon;

          // Convert icon string to IconData
          switch (locationData['icon'] as String? ?? '') {
            case 'house':
              icon = FontAwesomeIcons.house;
              break;
            case 'store':
              icon = FontAwesomeIcons.store;
              break;
            case 'building':
              icon = FontAwesomeIcons.building;
              break;
            case 'warehouse':
              icon = FontAwesomeIcons.warehouse;
              break;
            default:
              icon = FontAwesomeIcons.locationDot;
          }

          locationsList.add({
            'name': locationData['name'] as String? ?? 'Location',
            'description': locationData['description'] as String? ?? '',
            'icon': icon,
          });
        }
      } else {
        // Fallback to default locations if none found in Firebase
        locationsList.addAll([
          {
            'name': 'Home Service',
            'description': 'Service at your location',
            'icon': FontAwesomeIcons.house,
          },
          {
            'name': 'Shop Service',
            'description': 'Service at provider\'s workshop',
            'icon': FontAwesomeIcons.store,
          },
        ]);
      }

      setState(() {
        _serviceLocations = locationsList;
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error loading service locations: $e');
      // Fallback to default locations in case of error
      setState(() {
        _serviceLocations = [
          {
            'name': 'Home Service',
            'description': 'Service at your location',
            'icon': FontAwesomeIcons.house,
          },
          {
            'name': 'Shop Service',
            'description': 'Service at provider\'s workshop',
            'icon': FontAwesomeIcons.store,
          },
        ];
        _isLoadingLocations = false;
      });
    }
  }

  // Load payment methods (only Cash for now)
  Future<void> _loadPaymentMethods() async {
    try {
      // For now, only use Cash as payment method
      setState(() {
        _paymentMethods = ['Cash'];
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      print('Error loading payment methods: $e');
      // Fallback to Cash only
      setState(() {
        _paymentMethods = ['Cash'];
        _isLoadingPaymentMethods = false;
      });
    }
  }

  // Load user's saved locations
  Future<void> _loadSavedLocations() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('Loading saved locations for user: $userId');

      if (userId != null) {
        final locationsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .get();

        print(
            'Found ${locationsSnapshot.docs.length} saved locations in Firestore');

        final locationsList = <Map<String, String>>[];
        for (var doc in locationsSnapshot.docs) {
          final locationData = doc.data() as Map<String, dynamic>;
          print('Location data: $locationData');

          locationsList.add({
            'name': locationData['label'] as String? ?? 'Location',
            'address': locationData['address'] as String? ?? '',
            'icon': locationData['type'].toString().toLowerCase() as String? ??
                'home',
          });
        }

        print('Processed locations list: $locationsList');

        setState(() {
          _savedLocations = locationsList;
          _isLoadingSavedLocations = false;
          print(
              'Updated _savedLocations state. Count: ${_savedLocations.length}');
        });
      } else {
        print('No user ID found');
        setState(() {
          _isLoadingSavedLocations = false;
        });
      }
    } catch (e) {
      print('Error loading saved locations: $e');
      setState(() {
        _isLoadingSavedLocations = false;
      });
    }
  }

  // Load current user's contact information
  Future<void> _loadUserContactInfo() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final phone = userData['phone'] as String? ?? '';
          final address = userData['address'] as String? ?? '';

          setState(() {
            _contactNumber = phone;
            _address = address;
            _contactNumberController.text = phone;
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      print('Error loading user contact info: $e');
    }
  }

  // Fallback method to load default data in case of errors
  void _loadDefaultData() {
    setState(() {
      _services = [
        {
          'id': 'default_1',
          'name': 'Electrical Repair',
          'description': 'Professional electrical repair services',
          'price': 400,
          'duration': '1-2 hours',
        },
        {
          'id': 'default_2',
          'name': 'Wiring Installation',
          'description': 'Complete wiring installation for homes and offices',
          'price': 800,
          'duration': '2-4 hours',
        },
        {
          'id': 'default_3',
          'name': 'Socket Installation',
          'description': 'Installation of electrical sockets and switches',
          'price': 200,
          'duration': '1 hour',
        },
        {
          'id': 'default_4',
          'name': 'Light Fixture Setup',
          'description': 'Installation of light fixtures and ceiling fans',
          'price': 300,
          'duration': '1-2 hours',
        },
        {
          'id': 'default_5',
          'name': 'Circuit Breaker Repair',
          'description': 'Repair and replacement of circuit breakers',
          'price': 500,
          'duration': '1-3 hours',
        },
        {
          'id': 'default_6',
          'name': 'Electrical Inspection',
          'description': 'Complete electrical system inspection',
          'price': 600,
          'duration': '2-3 hours',
        },
      ];

      _serviceLocations = [
        {
          'name': 'Home Service',
          'description': 'Service at your location',
          'icon': FontAwesomeIcons.house,
        },
        {
          'name': 'Shop Service',
          'description': 'Service at provider\'s workshop',
          'icon': FontAwesomeIcons.store,
        },
      ];

      _paymentMethods = [
        'Cash',
      ];

      _savedLocations = [
        {
          'name': 'Home',
          'address': '123 Main Street, Brgy. San Antonio, Quezon City',
          'icon': 'home'
        },
        {
          'name': 'Work',
          'address': '456 Business Ave, Makati City',
          'icon': 'building'
        },
        {
          'name': 'Mom\'s House',
          'address': '789 Family Street, Brgy. Santo Rosario, Manila',
          'icon': 'heart'
        },
      ];

      // Set default selections
      if (_services.isNotEmpty) {
        _selectedService = _services[0]['name'] as String;
      }

      _isLoadingServices = false;
      _isLoadingLocations = false;
      _isLoadingPaymentMethods = false;
      _isLoadingSavedLocations = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProviderInfoCard(),
                      const SizedBox(height: 24),
                      _buildServiceSelectionSection(),
                      const SizedBox(height: 24),
                      _buildDateTimeSection(),
                      const SizedBox(height: 24),
                      _buildServiceLocationSection(),
                      const SizedBox(height: 24),
                      _buildContactInfoSection(),
                      const SizedBox(height: 24),
                      _buildPaymentMethodSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                      const SizedBox(height: 24),
                      _buildPricingSection(),
                      const SizedBox(height: 32),
                      _buildBookButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: TextWidget(
          text: 'Book Service',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        centerTitle: true,
        background: Container(
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
        ),
      ),
      leading: TouchableWidget(
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
    );
  }

  Widget _buildProviderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('providers')
                      .doc(widget.providerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final data = snapshot.data!.data()!;
                      final profilePicture = data['profilePicture'] as String?;

                      if (profilePicture != null && profilePicture.isNotEmpty) {
                        // Show image from Firebase Storage
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: ClipOval(
                            child: Image.network(
                              profilePicture,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
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
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const FaIcon(
                        FontAwesomeIcons.user,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    );
                  },
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
                          text: widget.providerName,
                          fontSize: 18,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                        if (widget.verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.solidStar,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        TextWidget(
                          text: '${widget.rating} (${widget.reviews} reviews)',
                          fontSize: 13,
                          fontFamily: 'Medium',
                          color: AppColors.onSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    TextWidget(
                      text: '${widget.experience} years',
                      fontSize: 12,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: widget.description,
            fontSize: 14,
            fontFamily: 'Regular',
            color: AppColors.onSecondary.withOpacity(0.8),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TouchableWidget(
                  onTap: () => _viewProviderProfile(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.user,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'View Profile',
                          fontSize: 13,
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
                  onTap: () => _viewProviderRatings(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.solidStar,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'View Ratings',
                          fontSize: 13,
                          fontFamily: 'Bold',
                          color: Colors.amber.shade700,
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
    );
  }

  Widget _buildServiceSelectionSection() {
    if (_isLoadingServices) {
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
                    FontAwesomeIcons.gear,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Select Service',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
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
                    FontAwesomeIcons.gear,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: 'Select Service',
                  fontSize: 16,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
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
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'This provider has not added any services yet',
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  TouchableWidget(
                    onTap: () {
                      setState(() {
                        _isLoadingServices = true;
                      });
                      _loadProviderData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextWidget(
                        text: 'Refresh',
                        fontSize: 14,
                        fontFamily: 'Bold',
                        color: Colors.white,
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
                  FontAwesomeIcons.gear,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Select Service',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              final isSelected = _selectedService == service['name'];
              final price = service['price'] as num? ?? 0;
              final duration = service['duration'] as String? ?? '';

              return TouchableWidget(
                onTap: () {
                  setState(() {
                    _selectedService = service['name'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  width: 150,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: service['name'] as String,
                        fontSize: 13,
                        fontFamily: 'Bold',
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSecondary,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      TextWidget(
                        text: '₱${price.toInt()}',
                        fontSize: 12,
                        fontFamily: 'Bold',
                        color: AppColors.primary,
                      ),
                      if (duration.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        TextWidget(
                          text: duration,
                          fontSize: 10,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextWidget(
                          text: isSelected ? 'Selected' : 'Select',
                          fontSize: 10,
                          fontFamily: 'Bold',
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
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
                  FontAwesomeIcons.calendar,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Schedule',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Schedule Now button
          TouchableWidget(
            onTap: () => _scheduleNow(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.bolt,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  TextWidget(
                    text: 'Schedule Now',
                    fontSize: 14,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TouchableWidget(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'Date',
                          fontSize: 12,
                          fontFamily: 'Medium',
                          color: AppColors.onSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text:
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'Time',
                          fontSize: 12,
                          fontFamily: 'Medium',
                          color: AppColors.onSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: _selectedTime.format(context),
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
      ),
    );
  }

  Widget _buildServiceLocationSection() {
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
                  FontAwesomeIcons.locationDot,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Service Location',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _serviceLocations.map((location) {
              final isSelected = _selectedLocation == location['name'];
              final isShopService = location['name'] == 'Shop Service';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IgnorePointer(
                  ignoring: isShopService, // Make Shop Service unclickable
                  child: Opacity(
                    opacity: isShopService
                        ? 0.5
                        : 1.0, // Dim Shop Service to indicate it's disabled
                    child: TouchableWidget(
                      onTap: isShopService
                          ? null
                          : () {
                              setState(() {
                                _selectedLocation = location['name'];
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FaIcon(
                                location['icon'] as IconData,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: location['name'] as String,
                                    fontSize: 14,
                                    fontFamily: 'Bold',
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.onSecondary,
                                  ),
                                  const SizedBox(height: 2),
                                  TextWidget(
                                    text: location['description'] as String,
                                    fontSize: 12,
                                    fontFamily: 'Regular',
                                    color:
                                        AppColors.onSecondary.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
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
                  FontAwesomeIcons.addressBook,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Contact Information',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              TextField(
                controller: _contactNumberController,
                decoration: InputDecoration(
                  hintText: 'Enter your mobile number',
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
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {
                    _contactNumber = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedLocation == 'Home Service')
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter complete address where service is needed',
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
                  onChanged: (value) {
                    setState(() {
                      _address = value;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
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
                  FontAwesomeIcons.creditCard,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Payment Method',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Only show Cash payment method
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods
                .where((method) => method == 'Cash') // Filter to only show Cash
                .map((method) {
              final isSelected = _paymentMethod == method;
              IconData methodIcon;
              Color methodColor;

              switch (method) {
                case 'Cash':
                  methodIcon = FontAwesomeIcons.moneyBill;
                  methodColor = Colors.green;
                  break;
                default:
                  methodIcon = FontAwesomeIcons.moneyBill;
                  methodColor = Colors.grey;
              }

              return TouchableWidget(
                onTap: () {
                  setState(() {
                    _paymentMethod = method;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? methodColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? methodColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        methodIcon,
                        color: isSelected ? methodColor : Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      TextWidget(
                        text: method,
                        fontSize: 13,
                        fontFamily: 'Medium',
                        color: isSelected ? methodColor : AppColors.onSecondary,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  color: Colors.blue,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextWidget(
                    text:
                        'Payment will be processed after service completion and your approval',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: Colors.blue.shade700,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
                  FontAwesomeIcons.noteSticky,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Additional Notes',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe your requirements, location details, or any special instructions...',
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
            onChanged: (value) {
              setState(() {
                _notes = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    // Get the selected service data
    Map<String, dynamic>? selectedServiceData;
    if (_selectedService.isNotEmpty) {
      selectedServiceData = _services.firstWhere(
        (service) => service['name'] == _selectedService,
        orElse: () => {},
      );
    }

    // Get service price (default to 0 if not found)
    final servicePrice = selectedServiceData?['price'] as num? ?? 0;
    final servicePriceFormatted = '₱${servicePrice.toInt()}';

    // Travel fee (could be customized per provider or service)
    // For now, we'll use a default value but this could be fetched from provider settings
    final travelFee = _selectedLocation == 'Home Service' ? 50 : 0;
    final travelFeeFormatted = '₱$travelFee';

    // Calculate total
    final total = servicePrice.toInt() + travelFee;
    final totalFormatted = '₱$total';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
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
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  FontAwesomeIcons.calculator,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                text: 'Pricing Estimate',
                fontSize: 16,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Service Fee', servicePriceFormatted),
          _buildPriceRow('Service Location', _selectedLocation),
          _buildPriceRow('Travel Fee', travelFeeFormatted),
          const Divider(thickness: 1),
          _buildPriceRow('Total Estimate', totalFormatted, isTotal: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  color: Colors.amber,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextWidget(
                    text:
                        'Final price may vary based on actual service requirements',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: Colors.amber.shade700,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextWidget(
            text: label,
            fontSize: isTotal ? 14 : 13,
            fontFamily: isTotal ? 'Bold' : 'Medium',
            color: AppColors.primary,
          ),
          TextWidget(
            text: value,
            fontSize: isTotal ? 16 : 13,
            fontFamily: 'Bold',
            color: isTotal ? AppColors.primary : AppColors.onSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: TouchableWidget(
        onTap: () {
          if (_isBookingValid()) {
            _handleBooking();
          } else {
            _showValidationError();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextWidget(
                text: 'Confirm Booking',
                fontSize: 16,
                fontFamily: 'Bold',
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isBookingValid() {
    // Check if a service is selected
    if (_selectedService.isEmpty) return false;

    // Check if contact number is provided
    if (_contactNumber.isEmpty) return false;

    // Check if address is provided for home service
    if (_selectedLocation == 'Home Service' && _address.isEmpty) return false;

    // Check if a payment method is selected
    if (_paymentMethod.isEmpty) return false;

    return true;
  }

  void _showValidationError() {
    String errorMessage = 'Please complete all required fields';

    if (_selectedService.isEmpty) {
      errorMessage = 'Please select a service';
    } else if (_contactNumber.isEmpty) {
      errorMessage = 'Please enter your contact number';
    } else if (_selectedLocation == 'Home Service' && _address.isEmpty) {
      errorMessage = 'Please enter your service address';
    } else if (_paymentMethod.isEmpty) {
      errorMessage = 'Please select a payment method';
    }

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
                color: Colors.red.withOpacity(0.1),
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
              text: 'Missing Information',
              fontSize: 16,
              fontFamily: 'Bold',
              color: Colors.red,
            ),
          ],
        ),
        content: TextWidget(
          text: errorMessage,
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary,
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'OK',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onSecondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onSecondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Schedule booking for immediate service
  void _scheduleNow() {
    final now = DateTime.now();
    final nowTime = TimeOfDay.fromDateTime(
        now.add(const Duration(minutes: 30))); // 30 minutes from now

    setState(() {
      _selectedDate = now;
      _selectedTime = nowTime;
    });

    // Show confirmation that schedule is set to now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextWidget(
          text: 'Scheduled for immediate service',
          fontSize: 14,
          fontFamily: 'Regular',
          color: Colors.white,
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBooking() {
    // Validate required fields
    if (_selectedService.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Please select a service',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Handling booking. Selected location: $_selectedLocation');
    print('Saved locations count: ${_savedLocations.length}');
    print('Loading saved locations: $_isLoadingSavedLocations');

    if (_selectedLocation == 'Home Service') {
      // Check if we're still loading saved locations
      if (_isLoadingSavedLocations) {
        print('Still loading saved locations, showing loading state');
        _showLoadingLocationsDialog();
        return;
      }

      // Check if there are saved locations before showing the dialog
      if (_savedLocations.isEmpty) {
        print('No saved locations found, showing no locations dialog');
        _showNoLocationsDialog();
      } else {
        print(
            'Showing location selection dialog with ${_savedLocations.length} locations');
        _showLocationSelectionDialog();
      }
    } else {
      _showBookingConfirmation(); // Show confirmation dialog
    }
  }

  void _showLoadingLocationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your saved locations...'),
          ],
        ),
      ),
    );

    // Re-check after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pop(); // Close loading dialog
      _handleBooking(); // Try again
    });
  }

  void _showLocationSelectionDialog() {
    print(
        'Showing location selection dialog. Saved locations count: ${_savedLocations.length}');

    // Check if there are no saved locations
    if (_savedLocations.isEmpty) {
      print('No saved locations in dialog, showing no locations dialog');
      _showNoLocationsDialog();
      return;
    }

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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                FontAwesomeIcons.locationDot,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'Select Service Location',
              fontSize: 16,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Choose from your saved locations:',
                fontSize: 14,
                fontFamily: 'Medium',
                color: AppColors.onSecondary,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount:
                      _savedLocations.length, // +1 for "Add New Location"
                  itemBuilder: (context, index) {
                    final location = _savedLocations[index];
                    IconData locationIcon;
                    Color iconColor;

                    switch (location['icon']) {
                      case 'home':
                        locationIcon = FontAwesomeIcons.house;
                        iconColor = Colors.blue;
                        break;
                      case 'building':
                        locationIcon = FontAwesomeIcons.building;
                        iconColor = Colors.orange;
                        break;
                      case 'heart':
                        locationIcon = FontAwesomeIcons.heart;
                        iconColor = Colors.red;
                        break;
                      default:
                        locationIcon = FontAwesomeIcons.locationDot;
                        iconColor = AppColors.primary;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: TouchableWidget(
                        onTap: () {
                          setState(() {
                            _selectedSavedLocation = location['name']!;
                            _address = location['address']!;
                          });
                          Navigator.of(context).pop();
                          _showBookingConfirmation();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FaIcon(
                                  locationIcon,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: location['name']!,
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    TextWidget(
                                      text: location['address']!,
                                      fontSize: 12,
                                      fontFamily: 'Regular',
                                      color: AppColors.onSecondary
                                          .withOpacity(0.7),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey.shade400,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'Cancel',
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoLocationsDialog() {
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
                FontAwesomeIcons.locationDot,
                color: Colors.orange,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'No Saved Locations',
              fontSize: 16,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ],
        ),
        content: TextWidget(
          text:
              'You need to add a location before booking a home service. Please go to your profile to add a saved location.',
          fontSize: 14,
          fontFamily: 'Regular',
          maxLines: 5,
          color: AppColors.onSecondary,
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
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
            onTap: () {
              Navigator.of(context).pop(); // Close this dialog
              Navigator.of(context).pop(); // Close location selection dialog

              // Show a snackbar with instructions to go to profile
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TextWidget(
                    text:
                        'Please tap on the Profile tab at the bottom to add a location',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: Colors.white,
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'Go to Profile',
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

  void _showAddNewLocationDialog() {
    String newLocationName = '';
    String newLocationAddress = '';

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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_location,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'Add New Location',
              fontSize: 16,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Home, Office, Friend\'s House',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) => newLocationName = value,
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Complete Address',
                hintText:
                    'Enter the full address including street, barangay, city',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) => newLocationAddress = value,
            ),
          ],
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
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
            onTap: () {
              if (newLocationName.isNotEmpty && newLocationAddress.isNotEmpty) {
                setState(() {
                  _selectedSavedLocation = newLocationName;
                  _address = newLocationAddress;
                });
                Navigator.of(context).pop();
                _showBookingConfirmation();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'Save & Use',
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

  void _showBookingConfirmation() {
    // Show booking confirmation dialog
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
                FontAwesomeIcons.check,
                color: Colors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'Confirm Booking',
              fontSize: 16,
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
              text: 'Please confirm your booking with ${widget.providerName}.',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Booking Details:',
                    fontSize: 12,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: 'Service: $_selectedService',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text: _selectedLocation == 'Home Service' &&
                            _selectedSavedLocation.isNotEmpty
                        ? 'Location: $_selectedSavedLocation${_address.isNotEmpty ? ' ($_address)' : ''}'
                        : 'Location: $_selectedLocation',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text:
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text: 'Time: ${_selectedTime.format(context)}',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text: 'Payment: $_paymentMethod',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  if (_contactNumber.isNotEmpty)
                    TextWidget(
                      text: 'Contact: $_contactNumber',
                      fontSize: 11,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary,
                    ),
                  if (_notes.isNotEmpty)
                    TextWidget(
                      text: 'Notes: $_notes',
                      fontSize: 11,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
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
            onTap: () {
              Navigator.of(context).pop();
              _saveBookingToFirebase();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
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
  }

  // Save booking to Firebase
  Future<void> _saveBookingToFirebase() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving your booking...'),
            ],
          ),
        ),
      );

      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(
            'Authentication Error', 'Please log in to book a service.');
        return;
      }

      // Find provider ID by name
      final providerId = await _findProviderIdByName(widget.providerName);
      if (providerId == null) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(
            'Provider Error', 'Could not find the service provider.');
        return;
      }

      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data() ?? {};
      final userFirstName = userData['firstName'] ?? '';
      final userLastName = userData['lastName'] ?? '';
      final userEmail = userData['email'] ?? '';
      final userPhone = userData['phone'] ?? '';
      final userFullName = [userFirstName, userLastName]
          .where((name) => name.isNotEmpty)
          .join(' ');

      // Get provider data
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();

      final providerData = providerDoc.data() ?? {};
      final providerFirstName = providerData['firstName'] ?? '';
      final providerLastName = providerData['lastName'] ?? '';
      final providerBusinessName = providerData['businessName'] ?? '';
      final providerEmail = providerData['email'] ?? '';
      final providerPhone = providerData['phone'] ?? '';
      final providerFullName = providerData['fullName'] ?? '';

      // Get selected service details
      final selectedService = _services.firstWhere(
        (service) => service['name'] == _selectedService,
        orElse: () => {
          'id': '',
          'name': _selectedService,
          'description': '',
          'price': 0,
          'duration': 'Not specified',
        },
      );

      // Format booking date and time
      final bookingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create booking data
      final bookingData = {
        // User Information
        'userId': userId,
        'userFirstName': userFirstName,
        'userLastName': userLastName,
        'userFullName': userFullName,
        'userEmail': userEmail,
        'userPhone': userPhone,

        // Provider Information
        'providerId': providerId,
        'providerFirstName': providerFirstName,
        'providerLastName': providerLastName,
        'providerFullName': providerFullName,
        'providerBusinessName': providerBusinessName,
        'providerEmail': providerEmail,
        'providerPhone': providerPhone,

        // Service Details
        'serviceName': _selectedService,
        'serviceId': selectedService['id'] ?? '',
        'serviceDescription': selectedService['description'] ?? '',
        'servicePrice': selectedService['price'] ?? 0,
        'serviceDuration': selectedService['duration'] ?? 'Not specified',

        // Booking Details
        'bookingDate': bookingDateTime,
        'bookingTimestamp': Timestamp.fromDate(bookingDateTime),

        // Location Information
        'locationType': _selectedLocation,
        'savedLocationName': _selectedSavedLocation,
        'address': _address,

        // Contact Information
        'contactNumber': _contactNumber,

        // Payment Details
        'paymentMethod': _paymentMethod,

        // Additional Information
        'notes': _notes,

        // Status Tracking
        'status': 'pending',

        // Timestamps
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      // Save booking to Firebase
      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      // Add or update customer in provider's customers subcollection
      final customerDocRef = FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .collection('customers')
          .doc(userId);

      // Check if customer already exists
      final customerDoc = await customerDocRef.get();

      // Set up customer data
      final customerData = {
        'id': userId,
        'name': userFullName,
        'email': userEmail,
        'phone': userPhone,
        'totalBookings': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(selectedService['price'] ?? 0),
        'avgRating':
            5.0, // Default rating or can be calculated from existing bookings
        'lastBookingDate': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add createdAt timestamp for new customers only
      if (!customerDoc.exists) {
        customerData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Save customer data
      await customerDocRef.set(customerData, SetOptions(merge: true));

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      _showBookingSuccessDialog(bookingRef.id);
    } catch (e) {
      print('Error saving booking: $e');
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(
          'Booking Error', 'Failed to save your booking. Please try again.');
    }
  }

  void _showBookingSuccessDialog(String bookingId) {
    // Show booking success dialog
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
                FontAwesomeIcons.check,
                color: Colors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            TextWidget(
              text: 'Booking Confirmed!',
              fontSize: 16,
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
              text:
                  'Your booking with ${widget.providerName} has been confirmed.',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Booking ID: $bookingId',
                    fontSize: 12,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: 'Service: $_selectedService',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text: _selectedLocation == 'Home Service' &&
                            _selectedSavedLocation.isNotEmpty
                        ? 'Location: $_selectedSavedLocation${_address.isNotEmpty ? ' ($_address)' : ''}'
                        : 'Location: $_selectedLocation',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text:
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text: 'Time: ${_selectedTime.format(context)}',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                  TextWidget(
                    text: 'Payment: $_paymentMethod',
                    fontSize: 11,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextWidget(
              text: 'You can view and manage your booking in the Bookings tab.',
              fontSize: 12,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
            ),
          ],
        ),
        actions: [
          TouchableWidget(
            onTap: () {
              Navigator.of(context).pop(); // Close success dialog
              Navigator.of(context).pop(); // Close booking screen
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'Done',
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

  void _showErrorDialog(String title, String message) {
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
                color: Colors.red.withOpacity(0.1),
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
              text: title,
              fontSize: 16,
              fontFamily: 'Bold',
              color: Colors.red,
            ),
          ],
        ),
        content: TextWidget(
          text: message,
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary,
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'OK',
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

  void _viewProviderProfile() {
    // Use the provider ID if available, otherwise find it by name
    if (widget.providerId != null && widget.providerId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProviderProfileScreen(
            providerId: widget.providerId!, // Use providerId if available
          ),
        ),
      );
    } else {
      // Get the provider ID by searching for the provider in Firebase
      _findProviderIdByName(widget.providerName).then((providerId) {
        if (providerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProviderProfileScreen(
                providerId: providerId,
              ),
            ),
          );
        } else {
          // Show error if provider not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Provider not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  // Helper method to find provider ID by name
  Future<String?> _findProviderIdByName(String providerName) async {
    try {
      // Try multiple approaches to find the provider
      print('Searching for provider with name: $providerName');

      // Approach 1: Try to match by fullName field (the standard way providers are stored)
      QuerySnapshot providersSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .where('fullName', isEqualTo: providerName)
          .where('applicationStatus', isEqualTo: 'approved')
          .get();
      print('Approach 1 - Found ${providersSnapshot.docs.length} providers');

      // Approach 2: Try matching by businessName
      if (providersSnapshot.docs.isEmpty) {
        providersSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .where('businessName', isEqualTo: providerName)
            .where('applicationStatus', isEqualTo: 'approved')
            .get();
        print('Approach 2 - Found ${providersSnapshot.docs.length} providers');
      }

      // Approach 3: Try to match by firstName field (in case stored differently)
      if (providersSnapshot.docs.isEmpty) {
        providersSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .where('firstName', isEqualTo: providerName)
            .where('applicationStatus', isEqualTo: 'approved')
            .get();
        print('Approach 3 - Found ${providersSnapshot.docs.length} providers');
      }

      if (providersSnapshot.docs.isNotEmpty) {
        // If multiple providers with same name, use the first one
        // In a real app, you'd want to pass provider ID to avoid this issue
        final providerDoc = providersSnapshot.docs.first;
        final providerId = providerDoc.id;
        print('Found provider with ID: $providerId');
        return providerId;
      } else {
        print('No provider found with name: $providerName');
        return null;
      }
    } catch (e) {
      print('Error finding provider by name: $e');
      return null;
    }
  }

  void _viewProviderRatings() {
    // Show loading dialog while fetching reviews
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading reviews...'),
          ],
        ),
      ),
    );

    // Fetch real reviews from Firebase
    _fetchProviderReviews();
  }

  Future<void> _fetchProviderReviews() async {
    try {
      // Get the provider document to find their ID
      QuerySnapshot providersSnapshot;

      // Try multiple approaches to find the provider
      final nameParts = widget.providerName.split(' ');

      print(
          'Searching for provider (for reviews) with name: ${widget.providerName}');

      // Approach 1: Try to match by fullName field (the standard way providers are stored)
      providersSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .where('fullName', isEqualTo: widget.providerName)
          .where('applicationStatus', isEqualTo: 'approved')
          .get();
      print(
          'Reviews - Approach 1 - Found ${providersSnapshot.docs.length} providers');

      // Approach 2: Try matching by businessName
      if (providersSnapshot.docs.isEmpty) {
        providersSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .where('businessName', isEqualTo: widget.providerName)
            .where('applicationStatus', isEqualTo: 'approved')
            .get();
        print(
            'Reviews - Approach 2 - Found ${providersSnapshot.docs.length} providers');
      }

      // Approach 3: Try to match by firstName field (in case stored differently)
      if (providersSnapshot.docs.isEmpty) {
        providersSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .where('firstName', isEqualTo: widget.providerName)
            .where('applicationStatus', isEqualTo: 'approved')
            .get();
        print(
            'Reviews - Approach 3 - Found ${providersSnapshot.docs.length} providers');
      }

      if (providersSnapshot.docs.isNotEmpty) {
        final providerId = providersSnapshot.docs.first.id;
        print('Found provider (for reviews) with ID: $providerId');

        // Get reviews for this provider
        final reviewsSnapshot =
            await FirebaseFirestore.instance.collection('bookings').get();

        final reviewsList = <Map<String, dynamic>>[];
        for (var doc in reviewsSnapshot.docs.where(
          (element) {
            return element['providerId'] == providerId &&
                element['rated'] == true;
          },
        )) {
          final reviewData = doc.data() as Map<String, dynamic>;
          reviewsList.add({
            'customerName': reviewData['userFullName'] as String? ?? 'Customer',
            'rating': reviewData['rating'] as num? ?? 0,
            'review': reviewData['review'] as String? ?? '',
            'date': _formatTimestamp(reviewData['bookingDate']),
            'service': reviewData['serviceName'] as String? ?? 'Service',
          });
        }

        // Close loading dialog and show reviews
        Navigator.of(context).pop(); // Close loading dialog
        _showReviewsDialog(reviewsList);
      } else {
        print(
            'No provider found (for reviews) with name: ${widget.providerName}');
        // Close loading dialog and show error
        Navigator.of(context).pop(); // Close loading dialog
        _showReviewsError();
      }
    } catch (e) {
      print('Error fetching provider reviews: $e');
      // Close loading dialog and show error
      Navigator.of(context).pop(); // Close loading dialog
      _showReviewsError();
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

  void _showReviewsDialog(List<Map<String, dynamic>> reviews) {
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
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Reviews & Ratings',
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.solidStar,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text:
                            '${widget.rating}/5.0 (${widget.reviews} reviews)',
                        fontSize: 12,
                        fontFamily: 'Medium',
                        color: AppColors.onSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.solidStar,
                        color: Colors.grey.withOpacity(0.5),
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      TextWidget(
                        text: 'No reviews yet',
                        fontSize: 14,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Be the first to review this provider',
                        fontSize: 12,
                        fontFamily: 'Regular',
                        color: AppColors.onSecondary.withOpacity(0.7),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: review['customerName'] as String,
                                fontSize: 13,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return FaIcon(
                                    starIndex <
                                            (review['rating'] as num).floor()
                                        ? FontAwesomeIcons.solidStar
                                        : FontAwesomeIcons.star,
                                    color: Colors.amber,
                                    size: 10,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextWidget(
                              text: review['service'] as String,
                              fontSize: 10,
                              fontFamily: 'Medium',
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: review['review'] as String,
                            fontSize: 12,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 6),
                          TextWidget(
                            text: review['date'] as String,
                            fontSize: 10,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.6),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
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

  void _showReviewsError() {
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
                color: Colors.red.withOpacity(0.1),
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
              text: 'Error Loading Reviews',
              fontSize: 16,
              fontFamily: 'Bold',
              color: Colors.red,
            ),
          ],
        ),
        content: TextWidget(
          text: 'Failed to load reviews. Please try again later.',
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary,
        ),
        actions: [
          TouchableWidget(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: 'OK',
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
}
